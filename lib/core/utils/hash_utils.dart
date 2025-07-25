import 'dart:io';
import 'image_utils.dart' as img;
import '../../app/services/firebase/wallpaper_db.dart';

/// Compute perceptual hash (pHash) of an image
Future<String> computeImageHash(File imageFile) async {
  return await img.computeImageHash(imageFile);
}
 
/// Function to check for duplicate wallpapers
  Future<bool> isDuplicateWallpaper(File newImage) async {
    final newImageHash = await computeImageHash(newImage);

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


