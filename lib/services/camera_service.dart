// lib/services/camera_service.dart
import 'dart:async';
import 'package:camera/camera.dart';

class CameraService {
  static CameraController? _controller;
  static List<CameraDescription> _cameras = [];
  static bool _isInitialized = false;
  static bool _isInitializing = false;
  static String? _initError;

  static bool get isInitialized => _isInitialized;
  static CameraController? get controller => _controller;
  static String? get initError => _initError;

  // ====================== INITIALIZATION ======================
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('✅ Camera already initialized');
      return;
    }

    if (_isInitializing) {
      print('⏳ Camera initialization already in progress...');
      int attempts = 0;
      while (_isInitializing && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (_isInitialized) return;
      if (_isInitializing) throw Exception('Camera initialization timeout');
    }

    _isInitializing = true;
    try {
      print('🔄 Initializing camera...');
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception('No cameras available');

      print('📷 Found ${_cameras.length} camera(s)');
      final camera = _cameras.first; // back camera
      print('🎥 Using camera: ${camera.name} (${camera.lensDirection})');

      _controller = CameraController(
        camera,
        ResolutionPreset.low, // low for faster inference
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Camera initialization timeout'),
      );

      _isInitialized = true;
      _initError = null;
      print('✅ Camera initialized successfully');
    } catch (e) {
      _initError = e.toString();
      print('❌ Camera initialization error: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  // ====================== IMAGE STREAM ======================
  static Future<void> startImageStream(Function(CameraImage) onFrame) async {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      print('⚠️ Camera not ready for streaming');
      return;
    }

    try {
      await _controller!.startImageStream((CameraImage image) {
        onFrame(image); // Directly pass CameraImage
      });
      print('✅ Image stream started successfully');
    } catch (e) {
      print('❌ Failed to start image stream: $e');
    }
  }

  static Future<void> stopImageStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
      print('⏹️ Image stream stopped');
    }
  }

  // ====================== DISPOSE ======================
  static Future<void> dispose() async {
    try {
      if (_controller != null) {
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }
        await _controller!.dispose();
      }
      _controller = null;
      _isInitialized = false;
      print('🗑️ Camera disposed');
    } catch (e) {
      print('⚠️ Camera disposal error: $e');
    }
  }
}
