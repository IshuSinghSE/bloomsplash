import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/collection_model.dart';
import '../../models/wallpaper_model.dart';

class CollectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'collections';

  // Create a new collection
  Future<void> createCollection(Collection collection) async {
    await _firestore.collection(_collectionPath).doc(collection.id).set(collection.toJson());
  }

  // Read a collection by ID
  Future<Collection?> getCollection(String id) async {
    final doc = await _firestore.collection(_collectionPath).doc(id).get();
    if (doc.exists) {
      return Collection.fromJson(doc.data()!);
    }
    return null;
  }

  // Read all collections
  Future<List<Collection>> getAllCollections() async {
    final query = await _firestore.collection(_collectionPath).get();
    return query.docs.map((doc) => Collection.fromJson(doc.data())).toList();
  }

  // Update a collection (by ID)
  Future<void> updateCollection(Collection collection) async {
    await _firestore.collection(_collectionPath).doc(collection.id).update(collection.toJson());
  }

  // Delete a collection (by ID)
  Future<void> deleteCollection(String id) async {
    await _firestore.collection(_collectionPath).doc(id).delete();
  }

  // Add a wallpaper to a collection
  Future<void> addWallpaperToCollection(String collectionId, String wallpaperId) async {
    await _firestore.collection(_collectionPath).doc(collectionId).update({
      'wallpaperIds': FieldValue.arrayUnion([wallpaperId])
    });
  }

  // Remove a wallpaper from a collection
  Future<void> removeWallpaperFromCollection(String collectionId, String wallpaperId) async {
    await _firestore.collection(_collectionPath).doc(collectionId).update({
      'wallpaperIds': FieldValue.arrayRemove([wallpaperId])
    });
  }

  // Get all wallpapers for a collection (by IDs)
  Future<List<Wallpaper>> getWallpapersForCollection(Collection collection) async {
    if (collection.wallpaperIds.isEmpty) return [];
    final query = await FirebaseFirestore.instance
        .collection('wallpapers')
        .where('id', whereIn: collection.wallpaperIds)
        .get();
    return query.docs.map((doc) => Wallpaper.fromJson(doc.data())).toList();
  }
}
