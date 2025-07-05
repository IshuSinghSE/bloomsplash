import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';
import '../../features/welcome/screens/welcome_page.dart';
import '../../features/shared/widgets/sync_confirmation_dialog.dart';
import '../services/firebase/user_db.dart';
import 'favorites_provider.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  GoogleSignIn? _googleSignIn;

  User? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  Future<void> cancelLogin() async {
    if (_googleSignIn != null) {
      await _googleSignIn!.disconnect(); // Disconnect the Google Sign-In session
      await _googleSignIn!.signOut(); // Sign out to force account chooser dialog
    }
    _isLoading = false;
    notifyListeners(); // Notify listeners to hide the loader
    debugPrint('Login process aborted by the user.');
  }

  Future<void> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign-In process...');
      
      _googleSignIn = GoogleSignIn(); // Initialize GoogleSignIn instance
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign-In canceled by user.');
        return; // Exit the method if the user cancels the login
      }

      // Set loading state only after the user selects an account
      _isLoading = true;
      notifyListeners(); // Notify listeners to show the loader

      debugPrint('Google user signed in: ${googleUser.displayName}, ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      debugPrint('Google auth details retrieved: accessToken=${googleAuth.accessToken}, idToken=${googleAuth.idToken}');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      _user = userCredential.user;
      _isLoggedIn = true;

      debugPrint('Firebase user signed in: ${_user?.displayName}, ${_user?.email}');

      // Log Google sign in event
      await FirebaseAnalytics.instance.logEvent(name: 'sign_in_google', parameters: {
        'email': _user?.email ?? '',
        'uid': _user?.uid ?? '',
      });

      // Save user data to local storage (will update after Firestore fetch below)
      var preferencesBox = Hive.box('preferences');
      preferencesBox.put('isLoggedIn', true);
      preferencesBox.put('isFirstLaunch', false);
      preferencesBox.put('userData', {
        'displayName': _user?.displayName,
        'email': _user?.email,
        'id': _user?.uid,
        'uid': _user?.uid, // Also store as 'uid' for consistency
        'photoUrl': _user?.photoURL,
        'isAdmin': false, // Default to false, will update after Firestore fetch
        // Add more fields as needed, but ensure no Timestamp objects are stored
      });

      // Clear any previous user's cached avatar
      await _clearPreviousUserCache();


      // Create the user document in Firestore on first login if it does not exist
      final firestoreService = UserService();
      final userDoc = await firestoreService.getUserProfile(_user!.uid);
      if (userDoc == null) {
        await firestoreService.saveOrUpdateUserProfile(
          uid: _user!.uid,
          name: _user!.displayName ?? '',
          email: _user!.email ?? '',
          photoURL: _user!.photoURL ?? '',
          savedWallpapers: [],
          uploadedWallpapers: [],
          isPremium: false,
          premiumPurchasedAt: null,
          authProvider: 'google', // or 'apple' if using Apple sign-in
          createdAt: DateTime.now(),
          isAdmin: false, // Always set to false for new users
        );
      }
      // Always fetch the latest user profile from Firestore and update Hive
      final latestUserDoc = await firestoreService.getUserProfile(_user!.uid);
      if (latestUserDoc != null) {
        // Defensive: handle both isAdmin and isadmin
        final isAdmin = latestUserDoc['isAdmin'] ?? latestUserDoc['isadmin'] ?? false;
        var userData = preferencesBox.get('userData', defaultValue: {});
        userData['isAdmin'] = isAdmin;
        preferencesBox.put('userData', userData);
      }

      // Sync favorites from Firestore after successful login
      await _syncFavoritesAfterLogin();

      notifyListeners();
    } catch (e) {
      debugPrint('Error during Google Sign-In: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners to hide the loader
    }
  }

  Future<void> signOut(BuildContext context) async {
    // Check for pending favorites sync
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    
    if (favoritesProvider.hasPendingChanges) {
      // Show confirmation dialog if there are unsaved changes
      await SyncConfirmationDialog.show(
        context,
        onConfirmSignOut: () => _performSignOut(context),
      );
    } else {
      // Proceed with normal sign out
      await _performSignOut(context);
    }
  }

  Future<void> _performSignOut(BuildContext context) async {
    try {
      // Clear only user-specific cached data (not wallpapers)
      await _clearUserSpecificCache();
      
      // Sign out from Google and Firebase
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      
      // Clear auth state
      _user = null;
      _isLoggedIn = false;

      // Log sign out event
      await FirebaseAnalytics.instance.logEvent(name: 'sign_out');

      // Clear all local storage
      await _clearAllLocalData();

      notifyListeners();

      // Navigate to WelcomePage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => WelcomePage(preferencesBox: Hive.box('preferences'))),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error during sign out: $e');
      // Still proceed with logout even if there's an error
      _user = null;
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  Future<void> checkLoginState() async {
    var preferencesBox = Hive.box('preferences');
    _isLoggedIn = preferencesBox.get('isLoggedIn', defaultValue: false);

    if (_isLoggedIn) {
      var userData = preferencesBox.get('userData');
      if (userData != null) {
        _user = FirebaseAuth.instance.currentUser;
        if (_user == null) {
          // Reauthenticate the user silently
          final GoogleSignInAccount? googleUser = await GoogleSignIn().signInSilently();
          if (googleUser != null) {
            final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
            final credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );
            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            _user = userCredential.user;
          }
        }
        if (_user != null) {
          userData['photoUrl'] = _user?.photoURL;
          preferencesBox.put('userData', userData);
          
          // Sync favorites from Firestore
          debugPrint('Syncing favorites from Firestore...');
          await _syncFavoritesAfterLogin();
          debugPrint('Favorites synced successfully.');
        }
      }
    }

    notifyListeners();
  }

  // Helper method to clear only user-specific cache (not wallpapers)
  Future<void> _clearUserSpecificCache() async {
    try {
      // Clear specific user avatar cache if user exists
      if (_user?.uid != null) {
        final cacheKey = 'user_avatar_${_user!.uid}';
        await DefaultCacheManager().removeFile(cacheKey);
        debugPrint('User avatar cache cleared for key: $cacheKey');
      }
      
      // Don't clear general image cache (wallpapers) to save bandwidth
      debugPrint('User-specific cache cleared successfully (wallpapers preserved)');
    } catch (e) {
      debugPrint('Error clearing user-specific cache: $e');
    }
  }

  // Helper method to clear all local data
  Future<void> _clearAllLocalData() async {
    try {
      // Clear preferences box
      var preferencesBox = Hive.box('preferences');
      await preferencesBox.clear();
      
      // Clear favorites box if it exists
      if (Hive.isBoxOpen('favorites')) {
        var favoritesBox = Hive.box<Map>('favorites');
        await favoritesBox.clear();
      }
      
      // Clear any other boxes that might store user-related data
      if (Hive.isBoxOpen('uploadedWallpapers')) {
        var uploadedWallpapersBox = Hive.box('uploadedWallpapers');
        await uploadedWallpapersBox.clear();
      }
      
      if (Hive.isBoxOpen('collections')) {
        var collectionsBox = Hive.box('collections');
        await collectionsBox.clear();
      }
      
      debugPrint('All local data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing local data: $e');
    }
  }

  // Helper method to clear previous user's cache during new login
  Future<void> _clearPreviousUserCache() async {
    try {
      // Get previous user data if exists
      var preferencesBox = Hive.box('preferences');
      var previousUserData = preferencesBox.get('userData');
      
      if (previousUserData != null && previousUserData['uid'] != null) {
        final previousCacheKey = 'user_avatar_${previousUserData['uid']}';
        await DefaultCacheManager().removeFile(previousCacheKey);
        debugPrint('Previous user avatar cache cleared for key: $previousCacheKey');
      }
    } catch (e) {
      debugPrint('Error clearing previous user cache: $e');
    }
  }

  // Method to refresh user avatar cache - can be called from UI if needed
  Future<void> refreshUserAvatar() async {
    if (_user?.uid != null && _user?.photoURL != null) {
      try {
        final cacheKey = 'user_avatar_${_user!.uid}';
        await DefaultCacheManager().removeFile(cacheKey);
        debugPrint('User avatar cache refreshed for: $cacheKey');
        notifyListeners(); // Trigger UI rebuild
      } catch (e) {
        debugPrint('Error refreshing user avatar cache: $e');
      }
    }
  }

  // Emergency method to clear ALL caches including wallpapers - use sparingly!
  Future<void> clearAllCaches() async {
    try {
      // This method can clear everything including wallpapers if explicitly requested
      await DefaultCacheManager().emptyCache();
      debugPrint('All caches cleared successfully (including wallpapers)');
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing all caches: $e');
    }
  }

  // Utility method to clear wallpaper cache if explicitly needed (bandwidth intensive)
  Future<void> clearWallpaperCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      debugPrint('Wallpaper cache cleared - this will use more bandwidth on next load');
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing wallpaper cache: $e');
    }
  }

  // Helper method to sync favorites from Firestore after login
  Future<void> _syncFavoritesAfterLogin() async {
    try {
      if (_user?.uid != null) {
        // Get the favorites provider from the context
        // Since we can't access context here, we'll use a different approach
        // by getting the favorites box directly
        final favoritesBox = Hive.box<Map>('favorites');
        
        // Get user's saved wallpapers from Firestore
        final firestoreService = UserService();
        final userProfile = await firestoreService.getUserProfile(_user!.uid);
        final savedIds = (userProfile?['savedWallpapers'] as List?)?.cast<String>() ?? [];
        
        // Clear local favorites first
        await favoritesBox.clear();
        
        // Fetch and store each favorite wallpaper
        for (final id in savedIds) {
          final wallpaper = await firestoreService.getImageDetailsFromFirestore(id);
          if (wallpaper != null) {
            // Ensure the document ID is included in the wallpaper data
            wallpaper['id'] = id;
            // The getImageDetailsFromFirestore already cleans the data for Hive
            await favoritesBox.add(wallpaper);
          }
        }
        
        debugPrint('Synced ${savedIds.length} favorites from Firestore');
      }
    } catch (e) {
      debugPrint('Error syncing favorites after login: $e');
    }
  }
}
