import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent, // Make navigation bar transparent
        systemNavigationBarIconBrightness: Brightness.light, // Adjust icon brightness if needed
        statusBarColor: Colors.transparent, // Make status bar transparent
        statusBarIconBrightness: Brightness.light, // Adjust status bar icon brightness if needed
        systemStatusBarContrastEnforced: false, // Disable contrast enforcement
        systemNavigationBarContrastEnforced: false, // Disable contrast enforcement
        systemNavigationBarDividerColor: Colors.transparent, // Make navigation bar divider transparent
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 48, 51, 65).withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 65, 90, 114).withOpacity(0.2),
                    blurRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  height: 56,
                  indicatorShape: const CircleBorder(),
                  indicatorColor: const Color.fromARGB(255, 21, 134, 226).withOpacity(0.7),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    onItemTapped(index);
                    switch (index) {
                      case 0:
                        Navigator.pushNamed(context, '/explore');
                        break;
                      case 1:
                        Navigator.pushNamed(context, '/collections');
                        break;
                      case 2:
                        Navigator.pushNamed(context, '/favorites');
                        break;
                      case 3:
                        Navigator.pushNamed(context, '/upload');
                        break;
                      default:
                        break;
                    }
                  },
                  // labelBehavior: NavigationDestinationLabelBehavior.alwaysHide, // Hide labels
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.explore),
                      label: 'Explore', // Label is hidden but tooltip remains
                      tooltip: 'Explore',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.collections),
                      label: 'Collections', // Label is hidden but tooltip remains
                      tooltip: 'Collections',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite),
                      label: 'Favorites', // Label is hidden but tooltip remains
                      tooltip: 'Favorites',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.upload_rounded),
                      label: 'Upload', // Label is hidden but tooltip remains
                      tooltip: 'Upload',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}