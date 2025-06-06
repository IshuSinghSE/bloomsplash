import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'app/providers/favorites_provider.dart';
import 'app/providers/auth_provider.dart';
import 'features/shared/widgets/custom_bottom_nav_bar.dart';
import 'features/explore/screens/explore_page.dart';
import 'features/explore/screens/explore_page.dart';
import 'features/favorites/screens/favorites_page.dart';
import 'features/upload/screens/upload_page.dart';
import 'features/welcome/screens/welcome_page.dart';
import 'features/settings/screens/settings_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/config/firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'core/constant/config.dart';
import 'features/collections/screens/collections_page.dart';

import 'core/constant/config.dart';
import 'features/collections/screens/collections_page.dart';


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
      androidProvider: AndroidProvider.playIntegrity,
    );
    debugPrint('Firebase App Check activated.');

    debugPrint('Initializing Hive...');
    await Hive.initFlutter();
    var preferencesBox = await Hive.openBox('preferences');
    await Hive.openBox<Map>('favorites');
    debugPrint('Hive initialized successfully.');

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
        '/collection': (context) => const CollectionsPage(),
        '/collection': (context) => const CollectionsPage(),
        '/favorites': (context) => const FavoritesPage(),
        '/upload': (context) => const UploadPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final Box preferencesBox;
  final int? initialSelectedIndex; // Add this parameter
  
  const HomePage({
    super.key, 
    required this.preferencesBox,
    this.initialSelectedIndex, // Make it optional
  });
  final int? initialSelectedIndex; // Add this parameter
  
  const HomePage({
    super.key, 
    required this.preferencesBox,
    this.initialSelectedIndex, // Make it optional
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;

  // Conditionally include the UploadPage tab
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    // Initialize _selectedIndex from the widget parameter if provided
    _selectedIndex = widget.initialSelectedIndex ?? 0;

    // Initialize _selectedIndex from the widget parameter if provided
    _selectedIndex = widget.initialSelectedIndex ?? 0;

    var userData = widget.preferencesBox.get('userData', defaultValue: {});
    final userEmail = userData['email'] ?? '';

    pages = [
      const ExplorePage(),
      const CollectionsPage(),
      const CollectionsPage(),
      const FavoritesPage(),
      if (userEmail == "ishu.111636@gmail.com") const UploadPage(),
    ];
  }

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.preferencesBox.get('userData', defaultValue: {});
    final userPhotoUrl = userData['photoUrl'];
    
    final userData = widget.preferencesBox.get('userData', defaultValue: {});
    final userPhotoUrl = userData['photoUrl'];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "BloomSplash",
          style: TextStyle(
            fontFamily: 'Raleway',
            fontFamily: 'Raleway',
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
                child: ClipOval(
                  child: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: userPhotoUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          cacheKey: 'user_avatar_${userData['uid'] ?? 'default'}',
                          placeholder: (context, url) => Image.asset(
                            AppConfig.avatarIconPath,
                            fit: BoxFit.cover,
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            AppConfig.avatarIconPath,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          AppConfig.avatarIconPath,
                          fit: BoxFit.cover,
                        ),
                ),
                child: ClipOval(
                  child: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: userPhotoUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          cacheKey: 'user_avatar_${userData['uid'] ?? 'default'}',
                          placeholder: (context, url) => Image.asset(
                            AppConfig.avatarIconPath,
                            fit: BoxFit.cover,
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            AppConfig.avatarIconPath,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          AppConfig.avatarIconPath,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              onPressed: () {
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: IndexedStack(
          key: ValueKey<int>(_selectedIndex),
          index: _selectedIndex, // Show the selected tab
          children: pages, // Preserve the state of all tabs
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          // Ensure the selected index is valid
          if (index < pages.length) {
            onItemTapped(index);
          }
        },
      ),
    );
  }
}
