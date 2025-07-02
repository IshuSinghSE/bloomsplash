import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/firebase/user_db.dart';
import 'dart:async';

class FavoritesProvider extends ChangeNotifier {
  final Box<Map> _favoritesBox = Hive.box<Map>('favorites');
  Timer? _syncTimer;
  bool _hasPendingChanges = false;
  static const int _syncDelaySeconds = 3; // 3 second delay for better UX

  // Getter to access the favorites
  List<Map<String, dynamic>> get favorites =>
      _favoritesBox.values.map((e) => Map<String, dynamic>.from(e)).toList();

  // Getter to check if there are pending sync changes
  bool get hasPendingChanges => _hasPendingChanges;

  // Debug method to log current state
  void logCurrentState() {
    final ids = _favoritesBox.values.map((fav) => fav['id'] as String).toList();
    debugPrint('=== FAVORITES DEBUG STATE ===');
    debugPrint('Local favorites count: ${_favoritesBox.length}');
    debugPrint('Local favorites IDs: $ids');
    debugPrint('Has pending changes: $_hasPendingChanges');
    debugPrint('Timer active: ${_syncTimer?.isActive ?? false}');
    debugPrint('===============================');
  }

  // Helper method to clean data for Hive compatibility
  Map<String, dynamic> _cleanDataForHive(Map<String, dynamic> data) {
    final cleaned = <String, dynamic>{};
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is DateTime) {
        cleaned[entry.key] = value.toIso8601String();
      } else if (value is List) {
        cleaned[entry.key] = value.map((item) {
          if (item is DateTime) return item.toIso8601String();
          return item;
        }).toList();
      } else if (value is Map) {
        cleaned[entry.key] = _cleanDataForHive(Map<String, dynamic>.from(value));
      } else {
        cleaned[entry.key] = value;
      }
    }
    return cleaned;
  }

  // Method to add a wallpaper to favorites
  void addFavorite(Map<String, dynamic> wallpaper) {
    if (!_favoritesBox.values.any((fav) => fav['id'] == wallpaper['id'])) {
      // Clean the wallpaper data for Hive compatibility
      final cleanedWallpaper = _cleanDataForHive(wallpaper);
      _favoritesBox.add(cleanedWallpaper);
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
  Future<void> syncFavoritesFromFirestore(String uid, {bool preserveLocal = false}) async {
    try {
      debugPrint('Starting favorites sync for user: $uid (preserveLocal: $preserveLocal)');
      debugPrint('Current state before sync:');
      logCurrentState();
      
      final firestoreService = UserService();
      final userProfile = await firestoreService.getUserProfile(uid);
      final savedIds = (userProfile?['savedWallpapers'] as List?)?.cast<String>() ?? [];
      debugPrint('Found ${savedIds.length} saved wallpaper IDs in Firestore');
      
      // Get current local favorites IDs to avoid unnecessary work
      final currentLocalIds = _favoritesBox.values.map((fav) => fav['id'] as String).toSet();
      final firestoreIds = savedIds.toSet();
      
      debugPrint('Current local favorites: $currentLocalIds');
      debugPrint('Firestore favorites: $firestoreIds');
      
      if (preserveLocal && _hasPendingChanges) {
        debugPrint('Has pending changes - will merge Firestore data with local changes');
        // We'll proceed but be more careful about preserving local data
      }
      
      // Special case: if Firestore is empty and we have local favorites and preserveLocal is true
      if (preserveLocal && savedIds.isEmpty && currentLocalIds.isNotEmpty) {
        debugPrint('Firestore is empty but we have local favorites and preserveLocal=true - keeping local favorites');
        return;
      }
      
      // Only clear and reload if there are differences
      if (!currentLocalIds.containsAll(firestoreIds) || !firestoreIds.containsAll(currentLocalIds)) {
        debugPrint('Local and Firestore favorites differ, syncing...');
        
        // Store current local favorites
        final localWallpapers = <String, Map<String, dynamic>>{};
        for (final entry in _favoritesBox.toMap().entries) {
          final wallpaper = Map<String, dynamic>.from(entry.value);
          final id = wallpaper['id'] as String;
          localWallpapers[id] = wallpaper;
        }
        debugPrint('Stored ${localWallpapers.length} local wallpapers for preservation');
        
        // Create a combined set of all IDs we need to have
        final allNeededIds = <String>{};
        allNeededIds.addAll(firestoreIds);
        if (preserveLocal) {
          allNeededIds.addAll(currentLocalIds);
        }
        debugPrint('Total IDs needed: ${allNeededIds.length} (Firestore: ${firestoreIds.length}, Local: ${currentLocalIds.length})');
        
        _favoritesBox.clear();
        debugPrint('Cleared local favorites box');
        
        // Add all needed favorites
        for (final id in allNeededIds) {
          Map<String, dynamic>? wallpaper;
          
          // First check if we have this wallpaper locally
          if (localWallpapers.containsKey(id)) {
            wallpaper = localWallpapers[id];
            debugPrint('Using locally preserved wallpaper: ${wallpaper!['title'] ?? wallpaper['id']}');
          } else {
            // Fetch from Firestore if not available locally
            wallpaper = await firestoreService.getImageDetailsFromFirestore(id);
            if (wallpaper != null) {
              // Ensure the document ID is included in the wallpaper data
              wallpaper['id'] = id;
              debugPrint('Fetched wallpaper from Firestore: ${wallpaper['title'] ?? wallpaper['id']}');
            } else {
              debugPrint('Warning: Could not fetch wallpaper details for ID: $id');
            }
          }
          
          if (wallpaper != null) {
            // Clean the wallpaper data for Hive compatibility
            final cleanedWallpaper = _cleanDataForHive(wallpaper);
            _favoritesBox.add(cleanedWallpaper);
            debugPrint('Added wallpaper to local box: ${cleanedWallpaper['title'] ?? cleanedWallpaper['id']}');
          }
        }
      } else {
        debugPrint('Local and Firestore favorites are already in sync, no changes needed');
      }
      
      debugPrint('Favorites sync completed. Final state:');
      logCurrentState();
      notifyListeners();
    } catch (e) {
      debugPrint('Error during favorites sync: $e');
    }
  }

  // Save current favorites to Firestore (after add/remove)
  Future<void> saveFavoritesToFirestore(String uid) async {
    final firestoreService = UserService();
    final ids = _favoritesBox.values.map((fav) => fav['id'] as String).toList();
    debugPrint('Saving ${ids.length} favorite IDs to Firestore: $ids');
    await firestoreService.updateUserSavedWallpapers(uid, ids);
    debugPrint('Successfully saved favorites to Firestore');
  }

  // Clear favorites on sign out (local only)
  void clearFavoritesOnSignOut() {
    _favoritesBox.clear();
    notifyListeners();
  }

  // Override toggleFavorite to sync with Firestore
  Future<void> toggleFavoriteWithSync(Map<String, dynamic> wallpaper, String uid) async {
    debugPrint('toggleFavoriteWithSync called for wallpaper: ${wallpaper['title'] ?? wallpaper['id']}');
    logCurrentState(); // Before toggle
    toggleFavorite(wallpaper);
    logCurrentState(); // After toggle
    _scheduleDebouncedSync(uid);
  }

  // Schedule a debounced sync to avoid too many API calls
  void _scheduleDebouncedSync(String uid) {
    debugPrint('_scheduleDebouncedSync called. Setting _hasPendingChanges = true');
    _hasPendingChanges = true;
    notifyListeners(); // Notify UI about pending changes
    
    // Cancel previous timer if exists
    _syncTimer?.cancel();
    debugPrint('Scheduled debounced sync in $_syncDelaySeconds seconds');
    
    // Schedule new sync after delay
    _syncTimer = Timer(Duration(seconds: _syncDelaySeconds), () async {
      try {
        debugPrint('Debounced timer fired, starting sync to Firestore...');
        await saveFavoritesToFirestore(uid);
        _hasPendingChanges = false;
        debugPrint('Debounced favorites sync completed successfully');
        notifyListeners(); // Notify UI that sync is complete
      } catch (e) {
        debugPrint('Error during debounced sync: $e');
        // Keep _hasPendingChanges as true if sync failed
      }
    });
  }

  // Force immediate sync (useful for logout or app closing)
  Future<void> forceSyncNow(String uid) async {
    debugPrint('forceSyncNow called. Canceling debounced timer.');
    _syncTimer?.cancel();
    try {
      debugPrint('Starting immediate sync to Firestore...');
      await saveFavoritesToFirestore(uid);
      _hasPendingChanges = false;
      debugPrint('Force sync completed successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error during force sync: $e');
      rethrow;
    }
  }
  
  // Special method for pull-to-refresh that merges data without losing local favorites
  Future<void> refreshAndMergeFavorites(String uid) async {
    try {
      debugPrint('Starting refresh and merge for user: $uid');
      
      final firestoreService = UserService();
      final userProfile = await firestoreService.getUserProfile(uid);
      final firestoreIds = (userProfile?['savedWallpapers'] as List?)?.cast<String>() ?? [];
      debugPrint('Found ${firestoreIds.length} saved wallpaper IDs in Firestore during refresh');
      
      // Get current local favorites
      final currentLocalIds = _favoritesBox.values.map((fav) => fav['id'] as String).toSet();
      debugPrint('Current local favorites: $currentLocalIds');
      debugPrint('Firestore favorites: ${firestoreIds.toSet()}');
      
      // Find IDs that are in Firestore but not in local storage
      final missingIds = firestoreIds.where((id) => !currentLocalIds.contains(id)).toList();
      debugPrint('Missing from local: $missingIds');
      
      // Fetch and add missing wallpapers from Firestore
      for (final id in missingIds) {
        final wallpaper = await firestoreService.getImageDetailsFromFirestore(id);
        if (wallpaper != null) {
          wallpaper['id'] = id;
          // Clean the wallpaper data for Hive compatibility
          final cleanedWallpaper = _cleanDataForHive(wallpaper);
          _favoritesBox.add(cleanedWallpaper);
          debugPrint('Added missing wallpaper from Firestore: ${cleanedWallpaper['title'] ?? 'Untitled'}');
        } else {
          debugPrint('Warning: Could not fetch wallpaper details for ID: $id');
        }
      }
      
      // Remove local favorites that are no longer in Firestore (only if not pending sync)
      if (!_hasPendingChanges) {
        final localIdsToRemove = currentLocalIds.where((id) => !firestoreIds.contains(id)).toList();
        debugPrint('IDs to remove from local (not in Firestore): $localIdsToRemove');
        
        for (final idToRemove in localIdsToRemove) {
          final key = _favoritesBox.keys.firstWhere(
            (k) => _favoritesBox.get(k)?['id'] == idToRemove,
            orElse: () => null,
          );
          if (key != null) {
            final wallpaper = _favoritesBox.get(key);
            _favoritesBox.delete(key);
            debugPrint('Removed wallpaper not in Firestore: ${wallpaper?['title'] ?? 'Untitled'}');
          }
        }
      } else {
        debugPrint('Skipping removal of local-only favorites due to pending changes');
      }
      
      debugPrint('Refresh and merge completed. Final local favorites count: ${_favoritesBox.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error during refresh and merge: $e');
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}