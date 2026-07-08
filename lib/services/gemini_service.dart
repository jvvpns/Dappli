import 'dart:io';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  bool _isInitialized = false;

  static String? _activeModelName;
  static List<String> _candidateModels = [];

  void initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('⚠️ Error: GEMINI_API_KEY not found in .env');
      return;
    }
    _isInitialized = true;
    _resolveBestModel();
  }

  bool get isInitialized => _isInitialized;

  /// Resolves stable and supported Gemini models.
  Future<String> _resolveBestModel() async {
    if (_activeModelName != null && _candidateModels.isNotEmpty) {
      return _activeModelName!;
    }

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      _activeModelName = 'gemini-3.1-flash-lite-preview';
      return _activeModelName!;
    }

    try {
      final client = HttpClient();
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
      print('GeminiService: Fetching available models via HttpClient...');
      
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 10));
      final response = await request.close().timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        final models = data['models'] as List<dynamic>;

        final candidates = models.where((m) {
          final methods = m['supportedGenerationMethods'] as List<dynamic>?;
          return methods?.contains('generateContent') ?? false;
        }).toList();

        final names = candidates.map((m) => m['name'] as String).toList();
        
        _candidateModels = [];
        void addIfAvailable(String exactName) {
          final match = names.where((n) => n == 'models/$exactName').firstOrNull;
          if (match != null) {
            final cleanName = match.replaceAll('models/', '');
            if (!_candidateModels.contains(cleanName)) {
              _candidateModels.add(cleanName);
            }
          }
        }

        // Fallback Chain
        addIfAvailable('gemini-2.5-flash-lite'); 
        addIfAvailable('gemini-3.1-flash-lite-preview');
        addIfAvailable('gemini-3.1-flash-lite'); 
        addIfAvailable('gemini-2.5-flash');      
        addIfAvailable('gemini-2.5-pro');        
        addIfAvailable('gemini-3.1-pro');        
        
        // If strict matches fail, allow fuzzy fallback to whatever flash exists
        if (_candidateModels.isEmpty) {
           final fallback = names.where((n) => n.contains('flash')).firstOrNull;
           if (fallback != null) _candidateModels.add(fallback.replaceAll('models/', ''));
        }
      }
      
      // If the API hasn't populated any matches or request failed, use defaults safely
      if (_candidateModels.isEmpty) {
        _candidateModels = ['gemini-3.1-flash-lite-preview', 'gemini-2.5-flash-lite', 'gemini-2.5-flash'];
      }

      _activeModelName = _candidateModels.first;
      print('GeminiService: Initialized with model: $_activeModelName. Candidates: $_candidateModels');
      return _activeModelName!;
    } catch (e) {
      print('GeminiService: Model discovery failed ($e). Falling back to gemini-3.1-flash-lite-preview');
      _activeModelName ??= 'gemini-3.1-flash-lite-preview';
      if (_candidateModels.isEmpty) {
        _candidateModels = ['gemini-3.1-flash-lite-preview', 'gemini-2.5-flash-lite', 'gemini-2.5-flash'];
      }
      return _activeModelName!;
    }
  }

  /// Switches to the next available model if the current one fails.
  Future<bool> _attemptModelSwitch() async {
    if (_candidateModels.isEmpty || _activeModelName == null) return false;
    
    final currentIndex = _candidateModels.indexOf(_activeModelName!);
    if (currentIndex != -1 && currentIndex < _candidateModels.length - 1) {
      final nextModel = _candidateModels[currentIndex + 1];
      print('GeminiService: 🔄 Switching from $_activeModelName to $nextModel due to error.');
      _activeModelName = nextModel;
      return true;
    }
    return false;
  }

  // 1. Detect Ingredients from Image
  Future<List<Map<String, dynamic>>> detectFromImagePath(String imagePath) async {
    if (!_isInitialized) {
      // Try to initialize on the fly if needed
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        _isInitialized = true;
      } else {
        return [];
      }
    }

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return [];
    }

    try {
      final bytes = await File(imagePath).readAsBytes();
      
      final prompt = '''
      Analyze this image and perform a dense scan for ALL visible food ingredients (vegetables, proteins, aromatics, etc.).
      Do not stop at just one item. Identify every distinct ingredient you can see.
      
      Use this specific list as your primary reference for naming ingredients if they are a match:
      [Ampalaya, Banana, Beef, Broccoli, Cabbage, Calamansi, Carrots, Chicken, Chilli, Coconut, Crab, Egg, Eggplant, Garlic, Ginger, Monggo, Okra, Onion, Papaya, Pechay, Pork, Potato, Rice, Shrimp, Spinach, Spring onion, Squash, String beans, Tomato, Tomato Sauce]
      
      IMPORTANT: If you see an ingredient that is NOT on this list, YOU MUST STILL SCAN IT and give it a generic descriptive label.
      
      For each ingredient you find, provide a bounding box.
      Return the output *strictly* as a JSON array of objects with "label" and "box" keys.
      Format: [{"label": "ingredient name", "box": [ymin, xmin, ymax, xmax]}]
      The box coordinates must be integers between 0 and 1000 (representing 0% to 100% of the image).
      If no obvious ingredients are found, return an empty array [].
      ''';

      int retryCount = 0;
      const int maxRetries = 2;

      while (true) {
        final currentModelName = await _resolveBestModel();
        print('GeminiService: Attempting detection using model: $currentModelName');

        try {
          final modelWithJson = GenerativeModel(
            model: currentModelName,
            apiKey: apiKey,
            generationConfig: GenerationConfig(responseMimeType: 'application/json'),
          );

          final response = await modelWithJson.generateContent([
            Content.multi([
              TextPart(prompt),
              DataPart('image/jpeg', bytes),
            ])
          ]).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Gemini API Timeout'),
          );

          final text = response.text;
          if (text == null || text.isEmpty) return [];

          final parsed = jsonDecode(text);
          if (parsed is! List) return [];

          final List<Map<String, dynamic>> detections = [];
          for (var item in parsed) {
            if (item is Map && item.containsKey('label') && item.containsKey('box')) {
              final box = item['box'] as List;
              if (box.length == 4) {
                final ymin = (box[0] as num).toDouble();
                final xmin = (box[1] as num).toDouble();
                final ymax = (box[2] as num).toDouble();
                final xmax = (box[3] as num).toDouble();

                // Convert Gemini [0-1000] space to normalized [0.0 - 1.0] space
                final double x1 = xmin / 1000.0;
                final double y1 = ymin / 1000.0;
                final double x2 = xmax / 1000.0;
                final double y2 = ymax / 1000.0;

                detections.add({
                  'label': item['label'].toString(),
                  'confidence': 0.99, // Assume high confidence
                  'box': [x1, y1, x2, y2],
                });
              }
            }
          }

          // Reset active model to primary on success
          if (_candidateModels.isNotEmpty && _activeModelName != _candidateModels.first) {
            print('GeminiService: Success! Resetting to primary model for next call: ${_candidateModels.first}');
            _activeModelName = _candidateModels.first;
          }

          return detections;

        } catch (e) {
          final errorStr = e.toString().toLowerCase();
          final is503 = errorStr.contains('503') || errorStr.contains('unavailable') || errorStr.contains('overloaded') || errorStr.contains('high demand');
          final isTimeout = errorStr.contains('timeout') || errorStr.contains('deadline');
          final isQuota = errorStr.contains('429') || errorStr.contains('quota') || errorStr.contains('exceeded') || errorStr.contains('404');

          print('GeminiService: Error during content generation: $e');

          if ((is503 || isTimeout) && retryCount < maxRetries) {
            retryCount++;
            final delaySeconds = retryCount * 2;
            print('GeminiService: Retrying in ${delaySeconds}s ($retryCount/$maxRetries)...');
            await Future.delayed(Duration(seconds: delaySeconds));
            continue;
          }

          if ((isQuota || is503 || isTimeout) && await _attemptModelSwitch()) {
            retryCount = 0; // Reset retries for the new model
            continue;
          }

          rethrow;
        }
      }
    } catch (e) {
      print('GeminiService: Final detection failure: $e');
      return [];
    }
  }
}
