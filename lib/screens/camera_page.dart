// lib/pages/camera_page.dart
import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../services/ingredient_detection_service.dart';
import 'package:camera/camera.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final IngredientDetectionService _detectionService = IngredientDetectionService();

  bool _isProcessing = false;
  List<Map<String, dynamic>> _detections = [];

  @override
  void initState() {
    super.initState();
    _initializeAll();
  }

  Future<void> _initializeAll() async {
    await _detectionService.initialize();
    await CameraService.initialize();

    if (CameraService.controller != null && CameraService.controller!.value.isInitialized) {
      setState(() {});
      _startLiveDetection();
    } else {
      _showError('Camera failed to initialize.');
    }
  }

  void _startLiveDetection() {
    print('📹 Starting optimized image stream...');
    CameraService.startImageStream((CameraImage cameraImage) async {
      if (_isProcessing) return;
      _isProcessing = true;

      try {
        final results = await _detectionService.detectFromCameraImage(cameraImage);

        if (mounted) {
          setState(() => _detections = results);
        }
      } catch (e) {
        print('❌ Live detection error: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  void dispose() {
    CameraService.dispose();
    _detectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = CameraService.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: controller == null || !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        fit: StackFit.expand,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
          if (_detections.isNotEmpty) _buildDetectionsOverlay(),
        ],
      ),
    );
  }

  Widget _buildDetectionsOverlay() {
    return Stack(
      children: _detections.map((det) {
        final box = det['box'] as List<double>;
        final label = det['label'];
        final conf = (det['confidence'] * 100).toStringAsFixed(1);

        return Positioned(
          left: box[0],
          top: box[1],
          width: box[2] - box[0],
          height: box[3] - box[1],
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                color: Colors.green,
                padding: const EdgeInsets.all(4),
                child: Text(
                  '$label ($conf%)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
