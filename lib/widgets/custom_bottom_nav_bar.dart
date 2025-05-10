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
                color: const Color.fromARGB(255, 48, 51, 65).withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 65, 90, 114).withValues(alpha:0.2),
                    blurRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  height: 64,
                  indicatorShape: const CircleBorder(),
                  indicatorColor: const Color.fromARGB(255, 21, 134, 226).withValues(alpha:0.7),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    if (index != selectedIndex) {
                      onItemTapped(index); // Update the selected index
                    }
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.explore),
                      label: 'Explore', // Label is hidden but tooltip remains
                      tooltip: 'Explore',
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