import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/providers/favorites_provider.dart';
import 'app/providers/auth_provider.dart';
import 'features/home/screens/home_page.dart';
import 'features/welcome/screens/welcome_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class App extends StatelessWidget {
  final Box preferencesBox;
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  const App({
    super.key,
    required this.preferencesBox,
    required this.analytics,
    required this.observer,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkLoginState(),
        ),
      ],
      child: MaterialApp(
        title: 'BloomSplash',
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        navigatorObservers: [observer],
        home: AuthGate(preferencesBox: preferencesBox),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final Box preferencesBox;
  const AuthGate({super.key, required this.preferencesBox});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // If AuthProvider exposes a loading state, use it. Otherwise, assume false means not logged in.
    // If isLoggedIn is always non-nullable, remove the null check.
    if (authProvider.isLoggedIn == false) {
      return WelcomePage(preferencesBox: preferencesBox);
    }
    // User is logged in
    return HomePage(preferencesBox: preferencesBox);
  }
}
