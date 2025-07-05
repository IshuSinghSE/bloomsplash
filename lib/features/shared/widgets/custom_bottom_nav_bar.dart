import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'dart:ui';

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
    final isAdmin = userData['isAdmin'] ?? false;


    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // Adjust blur strength as needed
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(50, 0, 0, 12), // More transparent for glass effect
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .25), // Sleek subtle border
                  width: 1,
                ),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  height: 56,
                  indicatorShape: const CircleBorder(),
                  indicatorColor: const Color.fromARGB(180, 21, 134, 226),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    // Prevent selecting the Upload tab if it's not available
                    if (index == 3 && !isAdmin) return;
                    onItemTapped(index);
                  },
                  destinations: [
                    // Explore tab (all users)
                    GestureDetector(
                      onTap: () => onItemTapped(0),
                      child: Tooltip(
                        message: 'Explore',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedIndex == 0 ? const Color.fromARGB(180, 21, 134, 226) : Colors.transparent,
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            selectedIndex == 0 ? Icons.explore : Icons.explore_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Collections tab (all users)
                    GestureDetector(
                      onTap: () => onItemTapped(1),
                      child: Tooltip(
                        message: 'Collections',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedIndex == 1 ? const Color.fromARGB(180, 21, 134, 226) : Colors.transparent,
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            selectedIndex == 1 ? Icons.collections : Icons.collections_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Favorites tab (all users)
                    GestureDetector(
                      onTap: () => onItemTapped(2),
                      child: Tooltip(
                        message: 'Favorites',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedIndex == 2 ? const Color.fromARGB(180, 21, 134, 226) : Colors.transparent,
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            selectedIndex == 2 ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Upload tab (admin only)
                    if (isAdmin)
                      GestureDetector(
                        onTap: () => onItemTapped(3),
                        child: Tooltip(
                          message: 'Upload',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selectedIndex == 3 ? const Color.fromARGB(180, 21, 134, 226) : Colors.transparent,
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              selectedIndex == 3 ? Icons.upload_rounded : Icons.upload_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ),
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