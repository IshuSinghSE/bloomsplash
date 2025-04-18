import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import '../screens/welcome_page.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoggedIn = false;

  User? get user => _user;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> signInWithGoogle() async {
    try {
      // Disconnect any previously signed-in accounts to force account chooser
      // await GoogleSignIn().disconnect();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      debugPrint('Google user: $googleUser');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      debugPrint('Google auth: $googleAuth');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      _user = userCredential.user;
      _isLoggedIn = true;

      // Save user data to local storage
      var preferencesBox = Hive.box('preferences');
      preferencesBox.put('isLoggedIn', true);
      preferencesBox.put('isFirstLaunch', false);
      preferencesBox.put('userData', {
        'displayName': _user?.displayName,
        'email': _user?.email,
        'id': _user?.uid,
        'photoUrl': _user?.photoURL, // Ensure photoURL is saved
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error during Google sign-in: $e');
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
        if (_user != null) {
          // Ensure photoURL is updated in case it was missing
          userData['photoUrl'] = _user?.photoURL;
          preferencesBox.put('userData', userData);
        }
      }
    }

    notifyListeners();
  }
}
