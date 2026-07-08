import 'package:flutter/material.dart';
import '../models/detection_result.dart';

class DetectionOverlayWidget extends StatelessWidget {
  final List<DetectionResult> detections;
  final Size screenSize;

  const DetectionOverlayWidget({
    super.key,
    required this.detections,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: screenSize,
      painter: DetectionPainter(detections: detections),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;

  DetectionPainter({required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    // Pre-create reusable paint objects for better performance
    final boxPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final bgPaint = Paint()..color = Colors.greenAccent.withOpacity(0.9);

    for (final detection in detections) {
      final box = detection.boundingBox;

      // Skip invalid boxes
      if (box.width <= 0 || box.height <= 0) continue;

      // Draw bounding box
      canvas.drawRect(box, boxPaint);

      // Create label text with confidence
      final textSpan = TextSpan(
        text: '${detection.label} ${detection.confidencePercent}',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Clamp label position to stay within canvas
      final labelX = box.left.clamp(0.0, size.width - textPainter.width - 8);
      var labelY = box.top - textPainter.height - 4;

      // If label would go above canvas, show it inside the box
      if (labelY < 0) {
        labelY = box.top + 4;
      }

      // Draw label background
      final labelRect = Rect.fromLTWH(
        labelX,
        labelY,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRect(labelRect, bgPaint);

      // Draw label text
      textPainter.paint(canvas, Offset(labelX + 4, labelY + 2));
    }
  }

  @override
  bool shouldRepaint(DetectionPainter oldDelegate) {
    // Repaint if detection count changed or if it's a different list reference
    if (oldDelegate.detections.length != detections.length) {
      return true;
    }
    return !identical(oldDelegate.detections, detections);
  }
}