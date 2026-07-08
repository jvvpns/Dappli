import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageHelper {
  /// Plan B: Ultra-Compression for Firestore Base64 Storage
  /// 1. Resizes to max 600px (ideal for mobile gallery display).
  /// 2. Reduces quality to ~60% to minimize string length.
  /// 3. Convers to JPEG.
  static Future<File> compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return file;

      // Aggressive resize for Plan B (600px is enough for detail screens)
      const int maxDimension = 600;
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          image = img.copyResize(image, width: maxDimension);
        } else {
          image = img.copyResize(image, height: maxDimension);
        }
      }

      // 60% quality ensures the Base64 string stays well under Firestore's limit
      final compressedBytes = img.encodeJpg(image, quality: 60);

      final tempDir = await getTemporaryDirectory();
      final compressedFile = File('${tempDir.path}/temp_comp_b64_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      return await compressedFile.writeAsBytes(compressedBytes);
    } catch (e) {
      print('Compression error: $e');
      return file;
    }
  }
}
