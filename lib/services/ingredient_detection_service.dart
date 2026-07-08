import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';

class IngredientDetectionService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // ====================== INITIALIZATION ======================
  Future<void> initialize() async {
    try {
      // Load YOLOv8 TFLite model
      _interpreter = await Interpreter.fromAsset(
        'assets/models/filipino_ingredients.tflite',
        options: InterpreterOptions()..threads = 2,
      );

      // Load class labels
      final labelData =
          await rootBundle.loadString('assets/labels/labels.txt');
      _labels = labelData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      _isInitialized = true;
      debugPrint('TFLite model loaded — ${_labels.length} classes, '
          'input 640×640, output [1, 34, 8400]');
    } catch (e, stack) {
      _isInitialized = false;
      debugPrint('TFLite initialization failed: $e\n$stack');
    }
  }

  // ====================== NEW: DETECT FROM IMAGE FILE PATH ======================
  Future<List<Map<String, dynamic>>> detectFromImagePath(String imagePath) async {
    if (!_isInitialized || _interpreter == null) return [];

    try {
      // Read image file
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();

      // Try decoding with different methods for better compatibility
      img.Image? image;
      try {
        image = img.decodeImage(bytes);
      } catch (e) {
        debugPrint('Failed to decode with default decoder, trying JPEG: $e');
        image = img.decodeJpg(bytes);
      }

      if (image == null) {
        debugPrint('Failed to decode image from path: $imagePath');
        return [];
      }

      debugPrint('Image decoded: ${image.width}x${image.height}');
      return await _detectFromImage(image);
    } catch (e, stack) {
      debugPrint('Detection from path error: $e\n$stack');
      return [];
    }
  }

  // ====================== DETECTION FROM CAMERA IMAGE ======================
  Future<List<Map<String, dynamic>>> detectFromCameraImage(
      CameraImage cameraImage) async {
    if (!_isInitialized || _interpreter == null) return [];

    try {
      // Convert YUV420 → RGB
      final rgbImage = _convertYUV420toImage(cameraImage);
      return await _detectFromImage(rgbImage);
    } catch (e, stack) {
      debugPrint('Detection from camera error: $e\n$stack');
      return [];
    }
  }

  // ====================== CORE DETECTION LOGIC ======================
  Future<List<Map<String, dynamic>>> _detectFromImage(img.Image image) async {
    try {
      // Resize to 640x640 (model input size)
      final resized = img.copyResize(image, width: 640, height: 640);

      // Normalize to [0, 1] for float32 model input
      final input = List.generate(
        1,
            (_) => List.generate(
          640,
              (y) => List.generate(
            640,
                (x) {
              final pixel = resized.getPixel(x, y);
              final r = pixel.r.toDouble() / 255.0;
              final g = pixel.g.toDouble() / 255.0;
              final b = pixel.b.toDouble() / 255.0;
              return [r, g, b];
            },
          ),
        ),
      );

      // Output buffer: [1, 34, 8400]
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final totalSize = outputShape.reduce((a, b) => a * b);
      final output = List<double>.filled(totalSize, 0).reshape(outputShape);

      // Run inference
      _interpreter!.run(input, output);

      // Parse detections
      final parsed = _parseDetections(output[0]);
      return parsed;
    } catch (e, stack) {
      return [];
    }
  }

  // ====================== PARSE DETECTIONS (YOLOV8 FORMAT) ======================
  List<Map<String, dynamic>> _parseDetections(List<dynamic> rawOutput) {
    const double confThreshold = 0.60; //shown ingredient on the output
    final List<Map<String, dynamic>> detections = [];

    // rawOutput shape: [34, 8400]
    // Rows 0-3: bbox coordinates (x_center, y_center, width, height) in 640x640 space
    // Rows 4-33: class probabilities for 30 classes

    final int numPredictions = 8400;
    final int numClasses = 30;



    for (int i = 0; i < numPredictions; i++) {
      // Extract bbox coordinates (in 0-640 range)
      final double xCenter = rawOutput[0][i].toDouble();
      final double yCenter = rawOutput[1][i].toDouble();
      final double width = rawOutput[2][i].toDouble();
      final double height = rawOutput[3][i].toDouble();

      // Find the class with highest probability
      double maxConf = 0.0;
      int bestClass = 0;

      for (int c = 0; c < numClasses; c++) {
        final double classProb = rawOutput[4 + c][i].toDouble();
        if (classProb > maxConf) {
          maxConf = classProb;
          bestClass = c;
        }
      }

      // Skip low-confidence detections
      if (maxConf < confThreshold) continue;

      // Convert from center format to corner format (x1, y1, x2, y2) and normalize to [0.0 - 1.0]
      final double x1 = (xCenter - width / 2) / 640.0;
      final double y1 = (yCenter - height / 2) / 640.0;
      final double x2 = (xCenter + width / 2) / 640.0;
      final double y2 = (yCenter + height / 2) / 640.0;

      // Get label
      String label = 'unknown';
      if (bestClass >= 0 && bestClass < _labels.length) {
        label = _labels[bestClass];
      }

      detections.add({
        'label': label,
        'confidence': maxConf,
        'box': [x1, y1, x2, y2],
      });
    }

    debugPrint('Found ${detections.length} detections above '
        '${(confThreshold * 100).toStringAsFixed(0)}% confidence');

    // Apply NMS to remove duplicate detections
    return _applyNMS(detections, 0.55);
  }

  // ====================== NON-MAXIMUM SUPPRESSION ======================
  List<Map<String, dynamic>> _applyNMS(
      List<Map<String, dynamic>> detections,
      double iouThreshold
      ) {
    if (detections.isEmpty) return [];

    // Sort by confidence (highest first)
    detections.sort((a, b) =>
        (b['confidence'] as double).compareTo(a['confidence'] as double));

    final List<Map<String, dynamic>> keep = [];
    final List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;

      keep.add(detections[i]);
      final boxA = List<double>.from(detections[i]['box']);

      // Check all remaining boxes
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;

        final boxB = List<double>.from(detections[j]['box']);
        final iou = _calculateIoU(boxA, boxB);

        // Suppress overlapping boxes
        if (iou > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

      return keep;
  }

  // ====================== INTERSECTION OVER UNION ======================
  double _calculateIoU(List<double> boxA, List<double> boxB) {
    // Calculate intersection rectangle
    final double x1 = max(boxA[0], boxB[0]);
    final double y1 = max(boxA[1], boxB[1]);
    final double x2 = min(boxA[2], boxB[2]);
    final double y2 = min(boxA[3], boxB[3]);

    // No overlap
    if (x2 < x1 || y2 < y1) return 0.0;

    // Calculate areas
    final double intersection = (x2 - x1) * (y2 - y1);
    final double areaA = (boxA[2] - boxA[0]) * (boxA[3] - boxA[1]);
    final double areaB = (boxB[2] - boxB[0]) * (boxB[3] - boxB[1]);
    final double union = areaA + areaB - intersection;

    return intersection / union;
  }

  // ====================== YUV → RGB ======================
  img.Image _convertYUV420toImage(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final imgImage = img.Image(width: width, height: height);

    final Y = image.planes[0].bytes;
    final U = image.planes[1].bytes;
    final V = image.planes[2].bytes;
    final strideY = image.planes[0].bytesPerRow;
    final strideU = image.planes[1].bytesPerRow;
    final strideV = image.planes[2].bytesPerRow;

    // Convert YUV420 → RGB
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yp = y * strideY + x;
        final uvIndex = (y ~/ 2) * strideU + (x ~/ 2);

        final Yval = Y[yp];
        final Uval = U[uvIndex];
        final Vval = V[uvIndex];

        final r = (Yval + 1.402 * (Vval - 128)).clamp(0, 255).toInt();
        final g = (Yval -
            0.344136 * (Uval - 128) -
            0.714136 * (Vval - 128))
            .clamp(0, 255)
            .toInt();
        final b =
        (Yval + 1.772 * (Uval - 128)).clamp(0, 255).toInt();

        imgImage.setPixelRgb(x, y, r, g, b);
      }
    }

    return imgImage;
  }

  // ====================== CLEANUP ======================
  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
    debugPrint('🧹 IngredientDetectionService disposed');
  }
}