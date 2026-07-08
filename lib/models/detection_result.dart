// lib/models/detection_result.dart
import 'package:flutter/material.dart';

class DetectionResult {
  final String label;
  final double confidence;
  final Rect boundingBox;
  final DateTime timestamp;

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.timestamp,
  });

  // Helper getter for displaying confidence as percentage
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  // Check if confidence is high enough to be auto-added
  bool get isHighlyConfident => confidence >= 0.6; // 60% threshold

  // Check if detection is valid
  bool get isValid =>
      boundingBox.width > 0 &&
          boundingBox.height > 0 &&
          confidence > 0 &&
          label.isNotEmpty;

  @override
  String toString() {
    return 'DetectionResult(label: $label, confidence: ${confidencePercent}, box: ${boundingBox.toString()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectionResult &&
        other.label == label &&
        other.confidence == confidence &&
        other.boundingBox == boundingBox;
  }

  @override
  int get hashCode => Object.hash(label, confidence, boundingBox);

  // Create from raw detection map
  factory DetectionResult.fromMap(Map<String, dynamic> map) {
    final box = List<double>.from(map['box']);
    return DetectionResult(
      label: map['label'] as String,
      confidence: map['confidence'] as double,
      boundingBox: Rect.fromLTRB(box[0], box[1], box[2], box[3]),
      timestamp: DateTime.now(),
    );
  }

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'confidence': confidence,
      'box': [
        boundingBox.left,
        boundingBox.top,
        boundingBox.right,
        boundingBox.bottom,
      ],
      'timestamp': timestamp.toIso8601String(),
    };
  }
}