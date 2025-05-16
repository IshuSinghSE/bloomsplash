import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addImageToFavorites(String id) async {
    try {
      log('Adding image to favorites: $id');
      await _firestore.collection('favorites').doc(id).set({'id': id});
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
