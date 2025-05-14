import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

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

    // Retrieve user email from Hive
    var preferencesBox = Hive.box('preferences');
    var userData = preferencesBox.get('userData', defaultValue: {});
    final userEmail = userData['email'] ?? '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(199, 9, 9, 12), // Solid semi-transparent color
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: .08), // Sleek subtle border
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(230, 65, 90, 114),
                  blurRadius: 0,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 64,
                indicatorShape: const CircleBorder(),
                indicatorColor: const Color.fromARGB(180, 21, 134, 226),
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  // Prevent selecting the Upload tab if it's not available
                  if (index == 2 && userEmail != "ishu.111636@gmail.com") return;
                  onItemTapped(index);
                },
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.explore),
                    label: 'Explore',
                    tooltip: 'Explore',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.favorite),
                    label: 'Favorites',
                    tooltip: 'Favorites',
                  ),
                  if (userEmail == "ishu.111636@gmail.com")
                    const NavigationDestination(
                      icon: Icon(Icons.upload_rounded),
                      label: 'Upload',
                      tooltip: 'Upload',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}