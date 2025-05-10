import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/wallpaper_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final CollectionReference _wallpapersCollection =
  //     FirebaseFirestore.instance.collection('wallpapers');

  Future<void> addImageDetailsToFirestore(Wallpaper wallpaper) async {
    try {
      log('Adding wallpaper to Firestore: ${wallpaper.id}');
      final batch = FirebaseFirestore.instance.batch();
      final docRef = FirebaseFirestore.instance.collection('wallpapers').doc(wallpaper.id);
      batch.set(docRef, wallpaper.toJson());
      await batch.commit();
      log('Wallpaper added to Firestore successfully: ${wallpaper.id}');
    } catch (e) {
      log('Error adding wallpaper to Firestore: $e');
      throw Exception('Error adding wallpaper to Firestore: $e');
    }
  }

  Future<void> updateImageDetailsInFirestore({
    required String id,
    required String name,
    required String? imageUrl,
    required String? thumbnailUrl,
    required String? previewUrl,
    required int downloads,
    required String size,
    required String resolution,
    required String category,
    required String author,
    required String authorImage,
    required String description,
  }) async {
    try {
      log('Updating image details in Firestore: $id');
      await _firestore.collection('wallpapers').doc(id).update({
        'name': name,
        'image': imageUrl,
        'thumbnail': thumbnailUrl,
        'preview': previewUrl,
        'downloads': downloads,
        'size': size,
        'resolution': resolution,
        'category': category,
        'author': author,
        'authorImage': authorImage,
        'description': description,
      });
      log('Image details updated in Firestore successfully: $id');
    } catch (e) {
      log('Error updating image details in Firestore: $e');
      throw Exception('Error updating image details in Firestore: $e');
    }
  }

  Future<void> deleteImageDetailsFromFirestore(String id) async {
    try {
      log('Deleting image details from Firestore: $id');
      await _firestore.collection('wallpapers').doc(id).delete();
      log('Image details deleted from Firestore successfully: $id');
    } catch (e) {
      log('Error deleting image details from Firestore: $e');
      throw Exception('Error deleting image details from Firestore: $e');
    }
  }

  Future<Map<String, dynamic>?> getImageDetailsFromFirestore(String id) async {
    try {
      log('Fetching image details from Firestore: $id');
      final doc = await _firestore.collection('wallpapers').doc(id).get();
      if (doc.exists) {
        log('Image details fetched successfully: $id');
        return doc.data();
      } else {
        log('No image details found for ID: $id');
        return null;
      }
    } catch (e) {
      log('Error fetching image details from Firestore: $e');
      throw Exception('Error fetching image details from Firestore: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllImageDetailsFromFirestore() async {
    try {
      log('Fetching all image details from Firestore');
      final snapshot = await _firestore.collection('wallpapers').get();
      final List<Map<String, dynamic>> imageDetailsList = [];
      for (var doc in snapshot.docs) {
        imageDetailsList.add(doc.data());
      }
      log('All image details fetched successfully');
      return imageDetailsList;
    } catch (e) {
      log('Error fetching all image details from Firestore: $e');
      throw Exception('Error fetching all image details from Firestore: $e');
    }
  }

  Future<void> addImageToFavorites(String id) async {
    try {
      log('Adding image to favorites: $id');
      await _firestore.collection('favorites').doc(id).set({
        'id': id,
      });
      log('Image added to favorites successfully: $id');
    } catch (e) {
      log('Error adding image to favorites: $e');
      throw Exception('Error adding image to favorites: $e');
    }
  }

  Future<void> removeImageFromFavorites(String id) async {
    try {
      log('Removing image from favorites: $id');
      await _firestore.collection('favorites').doc(id).delete();
      log('Image removed from favorites successfully: $id');
    } catch (e) {
      log('Error removing image from favorites: $e');
      throw Exception('Error removing image from favorites: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteImages() async {
    try {
      log('Fetching favorite images');
      final snapshot = await _firestore.collection('favorites').get();
      final List<Map<String, dynamic>> favoriteImagesList = [];
      for (var doc in snapshot.docs) {
        favoriteImagesList.add(doc.data());
      }
      log('Favorite images fetched successfully');
      return favoriteImagesList;
    } catch (e) {
      log('Error fetching favorite images: $e');
      throw Exception('Error fetching favorite images: $e');
    }
  }

  Future<void> clearFavorites() async {
    try {
      log('Clearing all favorites');
      final snapshot = await _firestore.collection('favorites').get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      log('All favorites cleared successfully');
    } catch (e) {
      log('Error clearing favorites: $e');
      throw Exception('Error clearing favorites: $e');
    }
  }
}

