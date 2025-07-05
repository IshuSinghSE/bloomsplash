import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/config/firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'app.dart';


void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Perform all initialization before showing the app
  try {
    debugPrint('Initializing Firebase, Hive, Analytics, AppCheck in parallel...');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Future.wait([
      Hive.initFlutter(),
      FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.playIntegrity),
    ]);
    debugPrint('Firebase, Hive, AppCheck initialized.');

    var preferencesBox = await Hive.openBox('preferences');
    await Hive.openBox<Map>('favorites');
    debugPrint('Hive boxes opened.');

    // Now initialize FirebaseAnalytics and observer
    final analytics = FirebaseAnalytics.instance;
    final observer = FirebaseAnalyticsObserver(analytics: analytics);
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    await analytics.logEvent(name: 'app_launch');
    await analytics.logEvent(name: 'test_event', parameters: {'debug': 'true'});

    // Show the full app
    runApp(
      App(
        preferencesBox: preferencesBox,
        analytics: analytics,
        observer: observer,
      ),
    );
  } catch (e) {
    debugPrint('Error during initialization: $e');
    // Optionally, show an error screen here
  } finally {
    FlutterNativeSplash.remove();
  }
}
