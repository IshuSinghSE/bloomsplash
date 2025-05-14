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
                color: Colors.white.withOpacity(.08), // Sleek subtle border
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
                  GestureDetector(
                    onTap: () => onItemTapped(1),
                    child: Tooltip(
                      message: 'Favorites',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selectedIndex == 1 ? const Color.fromARGB(180, 21, 134, 226) : Colors.transparent,
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          selectedIndex == 1 ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (userEmail == "ishu.111636@gmail.com")
                    GestureDetector(
                      onTap: () => onItemTapped(2),
                      child: Tooltip(
                        message: 'Upload',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedIndex == 2 ? const Color.fromARGB(180, 21, 134, 226) : Colors.transparent,
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            selectedIndex == 2 ? Icons.upload_rounded : Icons.upload_outlined,
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
    );
  }
}