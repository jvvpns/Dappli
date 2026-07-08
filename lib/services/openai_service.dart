import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // Fallback model chain — ordered by preference (cheapest/fastest first)
  static const List<String> _defaultCandidates = [
    'gpt-4o-mini',
    'gpt-4.1-mini',
    'gpt-4o',
    'gpt-4.1',
    'gpt-4-turbo',
  ];

  static String? _activeModelName;
  static List<String> _candidateModels = [];

  String? get _apiKey => dotenv.env['OPENAI_API_KEY'];

  /// Resolves available OpenAI models via the /v1/models endpoint.
  Future<String> _resolveBestModel() async {
    if (_activeModelName != null && _candidateModels.isNotEmpty) {
      return _activeModelName!;
    }

    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      _activeModelName = _defaultCandidates.first;
      _candidateModels = List.from(_defaultCandidates);
      return _activeModelName!;
    }

    try {
      debugPrint('OpenAIService: Fetching available models...');
      final response = await http
          .get(
            Uri.parse('https://api.openai.com/v1/models'),
            headers: {'Authorization': 'Bearer $apiKey'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final modelIds = (data['data'] as List<dynamic>)
            .map((m) => m['id'] as String)
            .toSet();

        _candidateModels = _defaultCandidates
            .where((name) => modelIds.contains(name))
            .toList();
      }
    } catch (e) {
      debugPrint('OpenAIService: Model discovery failed ($e). Using defaults.');
    }

    if (_candidateModels.isEmpty) {
      _candidateModels = List.from(_defaultCandidates);
    }

    _activeModelName = _candidateModels.first;
    debugPrint(
        'OpenAIService: Active model: $_activeModelName. Candidates: $_candidateModels');
    return _activeModelName!;
  }

  /// Switches to the next available model if the current one fails.
  bool _attemptModelSwitch() {
    if (_candidateModels.isEmpty || _activeModelName == null) return false;

    final currentIndex = _candidateModels.indexOf(_activeModelName!);
    if (currentIndex != -1 && currentIndex < _candidateModels.length - 1) {
      final nextModel = _candidateModels[currentIndex + 1];
      debugPrint(
          'OpenAIService: 🔄 Switching from $_activeModelName → $nextModel');
      _activeModelName = nextModel;
      return true;
    }
    return false;
  }

  /// Sends a chat completion request. Retries on rate-limit / transient errors
  /// and switches to the next fallback model when needed.
  Future<String> chat({
    required String prompt,
    double temperature = 0.8,
    int maxTokens = 2000,
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY is missing from .env');
    }

    int retryCount = 0;
    const int maxRetries = 2;

    while (true) {
      final modelName = await _resolveBestModel();
      debugPrint('OpenAIService: Sending request using model: $modelName');

      try {
        final response = await http
            .post(
              Uri.parse(_baseUrl),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': modelName,
                'messages': [
                  {'role': 'user', 'content': prompt}
                ],
                'temperature': temperature,
                'max_tokens': maxTokens,
              }),
            )
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () => throw Exception('OpenAI API Timeout'),
            );

        final statusCode = response.statusCode;

        if (statusCode == 200) {
          // ✅ Success — reset to primary model for next call
          if (_candidateModels.isNotEmpty &&
              _activeModelName != _candidateModels.first) {
            debugPrint(
                'OpenAIService: Success! Resetting to primary model: ${_candidateModels.first}');
            _activeModelName = _candidateModels.first;
          }

          final decoded = jsonDecode(response.body);
          return decoded['choices'][0]['message']['content'] as String? ?? '';
        }

        // Handle error status codes
        final isRateLimit = statusCode == 429;
        final isServerError = statusCode >= 500;
        final errorBody = response.body;
        debugPrint(
            'OpenAIService: HTTP $statusCode error. Body: $errorBody');

        if ((isRateLimit || isServerError) && retryCount < maxRetries) {
          retryCount++;
          final delaySeconds = retryCount * 2;
          debugPrint(
              'OpenAIService: Retrying in ${delaySeconds}s ($retryCount/$maxRetries)...');
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        }

        if ((isRateLimit || isServerError) && _attemptModelSwitch()) {
          retryCount = 0;
          continue;
        }

        throw Exception('OpenAI API Error $statusCode: ${response.reasonPhrase}');
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        final isTimeout =
            errorStr.contains('timeout') || errorStr.contains('deadline');
        final isNetwork = errorStr.contains('socketexception') ||
            errorStr.contains('handshake') ||
            errorStr.contains('connection');

        debugPrint('OpenAIService: Exception caught: $e');

        if ((isTimeout || isNetwork) && retryCount < maxRetries) {
          retryCount++;
          final delaySeconds = retryCount * 2;
          debugPrint(
              'OpenAIService: Retrying in ${delaySeconds}s ($retryCount/$maxRetries)...');
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        }

        if ((isTimeout || isNetwork) && _attemptModelSwitch()) {
          retryCount = 0;
          continue;
        }

        rethrow;
      }
    }
  }
}
