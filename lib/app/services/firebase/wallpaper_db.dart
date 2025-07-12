import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/wallpaper_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _wallpapersCollection = 'wallpapers';

  // Reusable error handler for different operation types
  Exception _handleFirebaseException(FirebaseException e, String operation, {String? itemId, int? itemCount}) {
    log('Firebase error in $operation: ${e.code} - ${e.message}');
    
    switch (e.code) {
      case 'permission-denied':
        return Exception('$operation failed: You don\'t have permission to perform this action. Please check your account status.');
      case 'not-found':
        return Exception('$operation failed: ${itemId != null ? 'Item not found' : 'Resource not found'}. It may have been deleted.');
      case 'unavailable':
        return Exception('$operation failed: Service is temporarily unavailable. Please try again later.');
      case 'deadline-exceeded':
        String message = '$operation failed: Request timed out. Please check your internet connection and try again.';
        if (itemCount != null && itemCount > 10) {
          message += ' Try processing fewer items at once.';
        }
        return Exception(message);
      case 'resource-exhausted':
        String message = '$operation failed: Quota exceeded. Please try again later.';
        if (itemCount != null) {
          message = '$operation failed: Quota exceeded. Please reduce the number of items or try again later.';
        }
        return Exception(message);
      case 'invalid-argument':
        return Exception('$operation failed: Invalid data provided. Please check all fields and try again.');
      default:
        return Exception('$operation failed: ${e.message ?? 'Unknown Firebase error occurred'}');
    }
  }

  // Reusable wrapper for Firestore operations
  Future<T> _executeFirestoreOperation<T>(
    Future<T> Function() operation,
    String operationName, {
    String? itemId,
    int? itemCount,
    T? fallbackValue,
  }) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      if (fallbackValue != null) {
        log('Firebase error in $operationName: ${e.code} - ${e.message}');
        switch (e.code) {
          case 'permission-denied':
          case 'unavailable':
          case 'deadline-exceeded':
            log('Returning fallback value for $operationName');
            return fallbackValue;
          default:
            throw _handleFirebaseException(e, operationName, itemId: itemId, itemCount: itemCount);
        }
      } else {
        throw _handleFirebaseException(e, operationName, itemId: itemId, itemCount: itemCount);
      }
    } catch (e) {
      log('Unexpected error in $operationName: $e');
      if (e.toString().contains('$operationName failed:')) {
        rethrow; // Re-throw our custom exceptions
      }
      if (fallbackValue != null) {
        return fallbackValue;
      }
      throw Exception('$operationName failed: An unexpected error occurred. Please try again or contact support if the problem persists.');
    }
  }

  Future<void> addImageDetailsToFirestore(Wallpaper wallpaper) async {
    await _executeFirestoreOperation(
      () async {
        log('Adding wallpaper to Firestore: ${wallpaper.id}');
        final batch = FirebaseFirestore.instance.batch();
        final docRef = FirebaseFirestore.instance.collection('wallpapers').doc(wallpaper.id);
        batch.set(docRef, wallpaper.toJson());
        await batch.commit();
        log('Wallpaper added to Firestore successfully: ${wallpaper.id}');
      },
      'Upload',
      itemId: wallpaper.id,
    );
  }

  Future<void> updateImageDetailsInFirestore({
    required String id,
    required String name,
    required String? imageUrl,
    required String? thumbnailUrl,
    required int downloads,
    required String size,
    required String resolution,
    required String category,
    required String author,
    required String authorImage,
    required String description,
    required List<String> tags, // Add the tags parameter
  }) async {
    await _executeFirestoreOperation(
      () async {
        if (id.isEmpty) {
          throw Exception('Update failed: Wallpaper ID cannot be empty.');
        }
        
        log('Updating image details in Firestore: $id');
        await _firestore.collection('wallpapers').doc(id).update({
          'name': name,
          'image': imageUrl,
          'thumbnail': thumbnailUrl,
          'downloads': downloads,
          'size': size,
          'resolution': resolution,
          'category': category,
          'author': author,
          'authorImage': authorImage,
          'description': description,
          'tags': tags, // Include tags in the update
        });
        log('Image details updated in Firestore successfully: $id');
      },
      'Update',
      itemId: id,
    );
  }

  Future<void> deleteImageDetailsFromFirestore(String id) async {
    await _executeFirestoreOperation(
      () async {
        log('Deleting image details from Firestore: $id');
        await _firestore.collection('wallpapers').doc(id).delete();
        log('Image details deleted from Firestore successfully: $id');
      },
      'Delete',
      itemId: id,
    );
  }

  Future<List<Map<String, dynamic>>> getAllImageDetailsFromFirestore() async {
    return _executeFirestoreOperation(
      () async {
        log('Fetching all image details from Firestore');
        final snapshot = await _firestore.collection('wallpapers').get();
        final List<Map<String, dynamic>> imageDetailsList = [];
        for (var doc in snapshot.docs) {
          imageDetailsList.add(doc.data());
        }
        log('All image details fetched successfully');
        return imageDetailsList;
      },
      'Fetch',
      fallbackValue: <Map<String, dynamic>>[],
    );
  }

  Future<Map<String, dynamic>> getPaginatedWallpapers({
    required int limit,
    DocumentSnapshot? lastDocument,
  }) async {
    return _executeFirestoreOperation(
      () async {
        if (limit <= 0) {
          throw Exception('Pagination failed: Limit must be greater than 0.');
        }
        
        if (limit > 50) {
          throw Exception('Pagination failed: Limit cannot exceed 50 items per request.');
        }
        
        Query query = _firestore
            .collection('wallpapers')
            .orderBy('createdAt', descending: true)
            .limit(limit);

        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }

        final QuerySnapshot snapshot = await query.get();

        final List<Wallpaper> wallpapers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Wallpaper.fromJson(data);
        }).toList();

        return {
          'wallpapers': wallpapers,
          'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        };
      },
      'Load',
      itemCount: limit,
    );
  }

  Future<void> addBulkImageDetailsToFirestore(List<Wallpaper> wallpapers) async {
    await _executeFirestoreOperation(
      () async {
        if (wallpapers.isEmpty) {
          throw Exception('Bulk upload failed: No wallpapers provided to upload.');
        }
        
        if (wallpapers.length > 500) {
          throw Exception('Bulk upload failed: Too many wallpapers (${wallpapers.length}). Maximum 500 wallpapers per batch.');
        }
        
        final batch = FirebaseFirestore.instance.batch();
        for (var wallpaper in wallpapers) {
          final docRef = FirebaseFirestore.instance.collection('wallpapers').doc(wallpaper.id);
          batch.set(docRef, wallpaper.toJson());
        }
        await batch.commit();
        log('Bulk wallpapers added to Firestore successfully: ${wallpapers.length} items.');
      },
      'Bulk upload',
      itemCount: wallpapers.length,
    );
  }

  Future<List<Wallpaper>> getAllWallpapers() async {
    return _executeFirestoreOperation(
      () async {
        final querySnapshot = await _firestore.collection(_wallpapersCollection).get();
        return querySnapshot.docs
            .map((doc) => Wallpaper.fromJson(doc.data()))
            .toList();
      },
      'Fetch',
      fallbackValue: <Wallpaper>[],
    );
  }

  // Delete a wallpaper by ID
  Future<void> deleteWallpaper(String id) async {
    await _executeFirestoreOperation(
      () async {
        if (id.isEmpty) {
          throw Exception('Delete failed: Wallpaper ID cannot be empty.');
        }
        await _firestore.collection(_wallpapersCollection).doc(id).delete();
        log('Wallpaper deleted from Firestore: $id');
      },
      'Delete',
      itemId: id,
    );
  }

  /// Efficiently increment download count for a wallpaper (static for easy access)
  static Future<void> incrementDownloadCount(String wallpaperId) async {
    final docRef = FirebaseFirestore.instance.collection('wallpapers').doc(wallpaperId);
    await docRef.update({
      'downloads': FieldValue.increment(1),
    });
  }
}