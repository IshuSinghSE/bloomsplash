import 'package:bloomsplash/features/home/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../core/constant/config.dart';

class WelcomePage extends StatelessWidget {
  final Box preferencesBox;

  const WelcomePage({super.key, required this.preferencesBox});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

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

    return PopScope(
      canPop: !authProvider.isLoading,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && authProvider.isLoading) {
          await authProvider.cancelLogin(); // Abort the login process
          Future.delayed(Duration.zero, () {
            Fluttertoast.cancel(); // Clear any previous toasts
            Fluttertoast.showToast(
              msg: "Login interrupted. Please try again.",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.black,
              textColor: Colors.white,
            );
          });
        }
      },
      child: Stack(
        children: [
          Scaffold(
            body: Stack(
              children: [
                // Background image grid
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(AppConfig.welcomeImagePath),
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
                          Colors.black.withAlpha(0), // Replacing withValues(alpha:0.1)
                          Colors.black.withAlpha(0), // Replacing withValues(alpha:0.5)
                          Colors.black.withAlpha(255), // Replacing withValues(alpha:1)
                          Colors.black.withAlpha(255), // Replacing withValues(alpha:1)
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
                              minimumSize: const Size(280, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              disabledBackgroundColor: Colors.white, // Retain color when disabled
                              disabledForegroundColor: Colors.black54, // Retain text color when disabled
                            ),
                            onPressed: authProvider.isLoading
                                ? null // Disable button while loading
                                : () async {
                                    await authProvider.signInWithGoogle();
                                    if (!authProvider.isLoading && authProvider.isLoggedIn) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HomePage(preferencesBox: preferencesBox),
                                        ),
                                      );
                                    }
                                  },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (authProvider.isLoading)
                                  const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Image.asset(
                                    'assets/icons/google.webp',
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
          ),
          if (authProvider.isLoading)
            Container(
              color: Colors.black.withValues(alpha:0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}