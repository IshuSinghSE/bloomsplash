import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

 // Save or update user profile (including savedWallpapers)
  Future<void> saveOrUpdateUserProfile({
    required String uid,
    required String name,
    required String email,
    required String photoURL,
    required List<String> savedWallpapers,
    required List<String> uploadedWallpapers,
    required bool isPremium,
    required DateTime? premiumPurchasedAt,
    required String authProvider,
    required DateTime createdAt,
  }) async {
    final userDoc = _firestore.collection('users').doc(uid);
    await userDoc.set({
      'uid': uid,
      'name': name,
      'email': email,
      'photoURL': photoURL,
      'savedWallpapers': savedWallpapers,
      'uploadedWallpapers': uploadedWallpapers,
      'isPremium': isPremium,
      'premiumPurchasedAt': premiumPurchasedAt,
      'authProvider': authProvider,
      'createdAt': createdAt,
    }, SetOptions(merge: true));
  }

  // Get user profile (including savedWallpapers)
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // Update savedWallpapers for user
  Future<void> updateUserSavedWallpapers(String uid, List<String> savedWallpapers) async {
    await _firestore.collection('users').doc(uid).update({
      'savedWallpapers': savedWallpapers,
    });
  }

  // Clear savedWallpapers (on sign out, local only, but method for completeness)
  Future<void> clearUserSavedWallpapers(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'savedWallpapers': [],
    });
  }


  Future<Map<String, dynamic>?> getImageDetailsFromFirestore(String id) async {
    try {
      final doc = await _firestore.collection('wallpapers').doc(id).get();
      if (doc.exists) {
        return doc.data();
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Error fetching image details from Firestore: $e');
    }
  }

}