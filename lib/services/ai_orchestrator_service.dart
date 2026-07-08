import 'package:flutter/foundation.dart';

import 'gemini_service.dart';
import 'ingredient_detection_service.dart';

class AIOrchestratorService {
  final GeminiService _geminiService = GeminiService();
  final IngredientDetectionService _tfliteService = IngredientDetectionService();

  bool _isInitialized = false;
  bool _usingCloud = false;

  bool get isInitialized => _isInitialized;
  bool get usingCloud => _usingCloud;

  Future<void> initialize() async {
    // Initialize both services (GeminiService.initialize is synchronous)
    _geminiService.initialize();
    await _tfliteService.initialize();

    _isInitialized = true;
    debugPrint('AIOrchestratorService ready | '
        'Gemini: ${_geminiService.isInitialized} | '
        'TFLite: ${_tfliteService.isInitialized}');
  }

  Future<List<Map<String, dynamic>>> detectFromImagePath(String imagePath) async {
    if (!_isInitialized) {
      debugPrint('AIOrchestratorService not initialized — call initialize() first');
      return [];
    }

    // 1. Try Cloud AI (Gemini) first
    if (_geminiService.isInitialized) {
      try {
        final cloudResults = await _geminiService.detectFromImagePath(imagePath);
        if (cloudResults.isNotEmpty) {
          _usingCloud = true;
          debugPrint('☁️ Using Gemini cloud detection — ${cloudResults.length} result(s)');
          return cloudResults;
        }
      } catch (e) {
        debugPrint('Gemini detection failed, falling back to TFLite: $e');
      }
    }

    // 2. Fallback to Local AI (TFLite)
    _usingCloud = false;
    debugPrint('📱 Using TFLite local detection');
    return await _tfliteService.detectFromImagePath(imagePath);
  }

  void dispose() {
    _tfliteService.dispose();
  }
}
