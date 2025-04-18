import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/auth_provider.dart';

class WelcomePage extends StatelessWidget {
  final Box preferencesBox;

  const WelcomePage({super.key, required this.preferencesBox});

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
    return Scaffold(
      body: Stack(
        children: [
          // Background image grid
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/welcome.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay with content

          // Content
          Center(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withAlpha(0), // Replacing withOpacity(0.1)
                    Colors.black.withAlpha(0), // Replacing withOpacity(0.5)
                    Colors.black.withAlpha(255), // Replacing withOpacity(1)
                    Colors.black.withAlpha(255), // Replacing withOpacity(1)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Explore 4K Wallpapers',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Explore, Create, Share\nUltra 4K Wallpapers Now!',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                       
                        minimumSize: const Size(
                          280,
                          50,
                        ), // Set width and height directly
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () async {
                        await Provider.of<AuthProvider>(context, listen: false).signInWithGoogle();

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(preferencesBox: preferencesBox), // Pass preferencesBox here
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/google.png', // Ensure this path is correct
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Continue With Google',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // Bottom navigation bar
        ],
      ),
    );
  }
}
