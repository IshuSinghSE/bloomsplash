import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/favorites_provider.dart';
import 'widgets/custom_bottom_nav_bar.dart';
import 'screens/explore_page.dart';
import 'screens/collections_page.dart';
import 'screens/favorites_page.dart';
import 'screens/upload_page.dart';
import 'screens/settings_page.dart';
import 'constants/data.dart'; // Import the data.dart file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open a Hive box for storing favorite wallpapers
  await Hive.openBox<Map>('favorites');

  // Load wallpapers from the JSON file
  await loadWallpapers();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
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
      extendBody: true, // Ensures the bottom navigation bar floats over the background
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
              //       print('Search query: $value');
              //     },
              //   ),
              // ),
            ],
            
          ),
      
      appBar: AppBar(
        title: const Text(
          'Wallpapers',
          style: TextStyle(
            fontSize: 32,
          fontWeight: FontWeight.normal,
            fontFamily: 'Raleway',
          ),
        ),
        backgroundColor: const Color.fromARGB(239, 14, 128, 241).withOpacity(0.1),
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Tooltip(
              message: 'Settings',
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>const SettingsPage(),
                    ),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromARGB(255, 56, 91, 114),
                      width: 2.0,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/avatar/Itsycal.png'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
