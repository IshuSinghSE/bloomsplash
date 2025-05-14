import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../services/firebase/firebase_firestore_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final Box<Map> _favoritesBox = Hive.box<Map>('favorites');

  // Getter to access the favorites
  List<Map<String, dynamic>> get favorites =>
      _favoritesBox.values.map((e) => Map<String, dynamic>.from(e)).toList();

  // Method to add a wallpaper to favorites
  void addFavorite(Map<String, dynamic> wallpaper) {
    if (!_favoritesBox.values.any((fav) => fav['id'] == wallpaper['id'])) {
      _favoritesBox.add(wallpaper);
      notifyListeners(); // Notify listeners about the change
    }
  }

  // Method to remove a wallpaper from favorites
  void removeFavorite(Map<String, dynamic> wallpaper) {
    final key = _favoritesBox.keys.firstWhere(
      (k) => _favoritesBox.get(k)?['id'] == wallpaper['id'],
      orElse: () => null,
    );
    if (key != null) {
      _favoritesBox.delete(key);
      notifyListeners(); // Notify listeners about the change
    }
  }

  // Method to toggle a wallpaper's favorite status
  void toggleFavorite(Map<String, dynamic> wallpaper) {
    if (_favoritesBox.values.any((fav) => fav['id'] == wallpaper['id'])) {
      removeFavorite(wallpaper);
    } else {
      addFavorite(wallpaper);
    }
  }

  // Method to check if a wallpaper is a favorite
  bool isFavorite(Map<String, dynamic> wallpaper) {
    return _favoritesBox.values.any((fav) => fav['id'] == wallpaper['id']);
  }

  // Sync favorites from Firestore (on login or sync button)
  Future<void> syncFavoritesFromFirestore(String uid) async {
    final firestoreService = FirestoreService();
    final userProfile = await firestoreService.getUserProfile(uid);
    final savedIds = (userProfile?['savedWallpapers'] as List?)?.cast<String>() ?? [];
    _favoritesBox.clear();
    for (final id in savedIds) {
      final wallpaper = await firestoreService.getImageDetailsFromFirestore(id);
      if (wallpaper != null) {
        _favoritesBox.add(wallpaper);
      }
    }
    // After syncing locally, update Firestore to match local state (in case local changed)
    final localIds = _favoritesBox.values.map((fav) => fav['id'] as String).toList();
    await firestoreService.updateUserSavedWallpapers(uid, localIds);
    notifyListeners();
  }

  // Save current favorites to Firestore (after add/remove)
  Future<void> saveFavoritesToFirestore(String uid) async {
    final firestoreService = FirestoreService();
    final ids = _favoritesBox.values.map((fav) => fav['id'] as String).toList();
    await firestoreService.updateUserSavedWallpapers(uid, ids);
  }

  // Clear favorites on sign out (local only)
  void clearFavoritesOnSignOut() {
    _favoritesBox.clear();
    notifyListeners();
  }

  // Override toggleFavorite to sync with Firestore
  Future<void> toggleFavoriteWithSync(Map<String, dynamic> wallpaper, String uid) async {
    toggleFavorite(wallpaper);
    await saveFavoritesToFirestore(uid);
  }
}