import 'dart:convert';
import 'dart:io';

class StorageService {
  /// Plan B: Free Local Encoding
  /// Converts a physical image file into a Base64 string that can be stored in Firestore.
  /// Result is a "data:image/jpeg;base64,..." string.
  Future<String> convertToBase64(File imageFile) async {
    try {
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64String = base64Encode(imageBytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      throw Exception('Failed to encode image: $e');
    }
  }

  /// Since we are using Base64, there is no physical cloud deletion needed.
  /// The image is deleted when the Firestore document is deleted.
  Future<void> deleteImage(String imageUrl) async {
    // No-op for Base64 approach
  }
}
