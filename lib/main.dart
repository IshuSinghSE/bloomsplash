import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/favorites_provider.dart';
import 'widgets/custom_bottom_nav_bar.dart';
import 'screens/explore_page.dart';
import 'screens/collections_page.dart';
import 'screens/favorites_page.dart';
import 'screens/upload_page.dart';
import 'core/constants/data.dart';
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();

  // Open a Hive box for storing favorite wallpapers
  await Hive.openBox<Map>('favorites');

  // Load wallpapers from the JSON file
  try {
    await loadWallpapers();
    log('Wallpapers loaded successfully'); // Debug statement
  } catch (e) {
    log('Error loading wallpapers: $e'); // Debug statement
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => FavoritesProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpaper App',
      theme: ThemeData.dark(),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ExplorePage(),
    const CollectionsPage(),
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
    return Scaffold(
      extendBody:
          true, // Ensures the bottom navigation bar floats over the background
      body:
      // Main content
      Stack(
        children: [
          // Background image
          // Image.asset(
          //   'assets/background.jpg',
          //   fit: BoxFit.cover,
          //   width: double.infinity,
          //   height: double.infinity,
          // ),
          // Main content
          _pages[_selectedIndex],
          // Search bar
          // Positioned(
          //   top: 0,
          //   left: 4,
          //   right: 4,
          //   child: custom.SearchBar(
          //     onChanged: (value) {
          //       // Handle search input
          //       log('Search query: $value');
          //     },
          //   ),
          // ),
        ],
      ),

      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
