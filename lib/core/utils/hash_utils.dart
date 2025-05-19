import 'dart:io';
import 'package:image/image.dart' as img;
import '../../app/services/firebase/wallpaper_db.dart';

/// Compute perceptual hash (pHash) of an image
String computeImageHash(File imageFile) {
  final image = img.decodeImage(imageFile.readAsBytesSync());
  if (image == null) {
    throw Exception("Failed to decode image.");
  }

  // Resize to 8x8 and convert to grayscale
  final resized = img.copyResize(image, width: 8, height: 8);
  final grayscale = img.grayscale(resized);

  // Compute average pixel value
  final avgPixelValue =
      grayscale.getBytes().map((pixel) => pixel).reduce((a, b) => a + b) ~/
      grayscale.getBytes().length;

  // Generate hash based on whether pixel values are above or below the average
  final hash =
      grayscale
          .getBytes()
          .map((pixel) => pixel > avgPixelValue ? '1' : '0')
          .join();
  return hash;
}
 
/// Function to check for duplicate wallpapers
  Future<bool> isDuplicateWallpaper(File newImage) async {
    final newImageHash = computeImageHash(newImage);

    // Fetch existing hashes from Firestore
    final firestoreService = FirestoreService();
    final existingWallpapers =
        await firestoreService.getAllImageDetailsFromFirestore();

    for (var wallpaper in existingWallpapers) {
      if (wallpaper['hash'] == newImageHash) {
        return true; // Duplicate found
      }
    }
    return false; // No duplicates
  }

