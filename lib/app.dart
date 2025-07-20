import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/providers/favorites_provider.dart';
import 'app/providers/auth_provider.dart';
import 'features/home/screens/home_page.dart';
import 'features/welcome/screens/welcome_page.dart';
import 'features/explore/screens/explore_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class App extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
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
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        flutterLocalNotificationsPlugin.show(
          0,
          message.notification!.title,
          message.notification!.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Default',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@drawable/ic_stat_notify',
            ),
          ),
        );
      }
    });
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/explore',
        (route) => true,
        arguments: true, // Pass argument to trigger refresh
      );
    });

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkLoginState(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'BloomSplash',
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        navigatorObservers: [observer],
        routes: {
          '/explore': (context) => ExplorePage(),
        },
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
