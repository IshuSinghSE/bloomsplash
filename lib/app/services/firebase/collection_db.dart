import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../../models/collection_model.dart';
import '../../../models/wallpaper_model.dart';

// --- COLLECTION CRUD METHODS ---

class CollectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'collections';
  final String _wallpaperPath = 'wallpapers';

  // Create a collection
  Future<void> createCollection(Collection collection) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(collection.id)
          .set(collection.toJson());
      // Cache locally
      final box = await Hive.openBox(_collectionPath);
      await box.put(collection.id, collection.toJson());
    } catch (e) {
      log('Error creating collection: $e');
      throw Exception('Error creating collection: $e');
    }
  }

  // Read a collection by ID
  Future<Collection?> getCollection(String id) async {
    final doc = await _firestore.collection(_collectionPath).doc(id).get();
    if (doc.exists) {
      return Collection.fromJson(doc.data()!);
    }
    return null;
  }

  // Fetch all collections
  Future<List<Collection>> getAllCollections() async {
    final query = await _firestore.collection(_collectionPath).get();
    return query.docs.map((doc) => Collection.fromJson(doc.data())).toList();
  }

  // Update a collection
  Future<void> updateCollection(Collection collection) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(collection.id)
          .update(collection.toJson());
      // Update cache
      final box = await Hive.openBox(_collectionPath);
      await box.put(collection.id, collection.toJson());
    } catch (e) {
      log('Error updating collection: $e');
      throw Exception('Error updating collection: $e');
    }
  }

  // Delete a collection
  Future<void> deleteCollection(String id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).delete();
      // Remove from cache
      final box = await Hive.openBox(_collectionPath);
      await box.delete(id);
    } catch (e) {
      log('Error deleting collection: $e');
      throw Exception('Error deleting collection: $e');
    }
  }

  // Fetch wallpapers for a collection
  Future<List<Wallpaper>> getWallpapersForCollection(
    Collection collection,
  ) async {
    if (collection.wallpaperIds.isEmpty) return [];
    final snapshot =
        await _firestore
            .collection(_wallpaperPath)
            .where('id', whereIn: collection.wallpaperIds)
            .get();
    return snapshot.docs.map((doc) => Wallpaper.fromJson(doc.data())).toList();
  }

  // Add a wallpaper to a collection
  Future<void> addWallpaperToCollection(
    String collectionId,
    String wallpaperId,
  ) async {
    await _firestore.collection(_collectionPath).doc(collectionId).update({
      'wallpaperIds': FieldValue.arrayUnion([wallpaperId]),
    });
  }

  // Remove a wallpaper from a collection
  Future<void> removeWallpaperFromCollection(
    String collectionId,
    String wallpaperId,
  ) async {
    await _firestore.collection(_collectionPath).doc(collectionId).update({
      'wallpaperIds': FieldValue.arrayRemove([wallpaperId]),
    });
  }
}
