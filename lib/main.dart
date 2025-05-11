import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/favorites_provider.dart';
import 'providers/auth_provider.dart';
import 'widgets/custom_bottom_nav_bar.dart';
import 'screens/explore_page.dart';
// import 'screens/collections_page.dart';
import 'screens/favorites_page.dart';
import 'screens/upload_page.dart';
import 'screens/welcome_page.dart';
import 'screens/settings_page.dart';
// import 'core/constants/data.dart';
// import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');

    // Initialize Firebase App Check
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity, // Use Play Integrity for Android
      // appleProvider: AppleProvider.deviceCheck, // Use DeviceCheck for iOS
      //  webRecaptchaSiteKey: 'your-recaptcha-site-key', // Only for web
    );
    debugPrint('Firebase App Check activated.');

    debugPrint('Initializing Hive...');
    await Hive.initFlutter();
    var preferencesBox = await Hive.openBox('preferences');
    await Hive.openBox<Map>('favorites');
    debugPrint('Hive initialized successfully.');

    // var userData = preferencesBox.get('userData', defaultValue: {});
    // if (userData != null && userData.isNotEmpty) {
    //   debugPrint('User is logged in. Loading wallpapers...');
    //   await loadWallpapers();
    //   debugPrint('Wallpapers loaded successfully.');
    // } else {
    //   debugPrint('User is not logged in.');
    // }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => FavoritesProvider()),
          ChangeNotifierProvider(
            create: (_) => AuthProvider()..checkLoginState(),
          ),
        ],
        child: MyApp(preferencesBox: preferencesBox),
      ),
    );
  } catch (e) {
    debugPrint('Error during initialization: $e');
  } finally {
    FlutterNativeSplash.remove();
  }
}

class MyApp extends StatelessWidget {
  final Box preferencesBox;

  const MyApp({super.key, required this.preferencesBox});

  @override
  Widget build(BuildContext context) {
    bool isFirstLaunch = preferencesBox.get(
      'isFirstLaunch',
      defaultValue: true,
    );

    return MaterialApp(
      title: 'Wallpaper App',
      theme: ThemeData.dark(),
      home:
          isFirstLaunch
              ? WelcomePage(preferencesBox: preferencesBox)
              : HomePage(preferencesBox: preferencesBox),
      debugShowCheckedModeBanner: false,
      routes: {
        '/explore': (context) => const ExplorePage(),
        '/favorites': (context) => const FavoritesPage(),
        '/upload': (context) => const UploadPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final Box preferencesBox;
  const HomePage({super.key, required this.preferencesBox});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ExplorePage(),
    const FavoritesPage(),
    const UploadPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    var userData = widget.preferencesBox.get('userData', defaultValue: {});

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Wallpapers", // Dynamic title
          style: TextStyle(
            fontFamily: 'Raleway', // Use Raleway font
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: CircleAvatar(
                backgroundImage:
                    userData != null &&
                            userData['photoUrl'] != null &&
                            userData['photoUrl']!.isNotEmpty
                        ? NetworkImage(userData['photoUrl']!)
                        : const AssetImage('assets/icons/avatar.png')
                            as ImageProvider,
              ),
              onPressed: () {
                // Handle account action
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ),
        ],
      ),
      extendBody: true, // Ensures the bottom navigation bar floats over the background
      body: IndexedStack(
        index: _selectedIndex, // Show the selected tab
        children: _pages, // Preserve the state of all tabs
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
