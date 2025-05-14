import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import '../../features/welcome/screens/welcome_page.dart';
import '../constants/data.dart';
import '../../services/firebase/firebase_firestore_service.dart';

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

      // Save user data to local storage
      var preferencesBox = Hive.box('preferences');
      preferencesBox.put('isLoggedIn', true);
      preferencesBox.put('isFirstLaunch', false);
      preferencesBox.put('userData', {
        'displayName': _user?.displayName,
        'email': _user?.email,
        'id': _user?.uid,
        'photoUrl': _user?.photoURL,
      });

      // Create the user document in Firestore on first login if it does not exist
      final firestoreService = FirestoreService();
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
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error during Google Sign-In: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners to hide the loader
    }
  }

  Future<void> signOut(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    _user = null;
    _isLoggedIn = false;

    // Clear local storage
    var preferencesBox = Hive.box('preferences');
    preferencesBox.clear();

    notifyListeners();

    // Navigate to WelcomePage
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => WelcomePage(preferencesBox: preferencesBox)),
      (route) => false,
    );
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

          // Load wallpapers after login
          debugPrint('User is logged in. Loading wallpapers...');
          await loadWallpapers();
          debugPrint('Wallpapers loaded successfully.');
        }
      }
    }

    notifyListeners();
  }
}
