import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle, PlatformException;
// import 'package:android_content_provider/android_content_provider.dart'; // Add this package for MediaStore API
import 'package:media_scanner/media_scanner.dart'; // Add this package for MediaScanner
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class DetailsContainer extends StatelessWidget {
  final Map<String, dynamic> wallpaper; // Wallpaper data
  final bool showMetadata; // Whether to show the metadata row
  final Animation<Offset> slideAnimation; // Animation for metadata row
  final VoidCallback toggleMetadata; // Callback to toggle metadata visibility

  const DetailsContainer({
    super.key,
    required this.wallpaper,
    required this.showMetadata,
    required this.slideAnimation,
    required this.toggleMetadata,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Container(
            width: double.infinity,
            color: Colors.black.withOpacity(0.6),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author Image, Wallpaper Title, and Description
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(wallpaper['authorImage']),
                      radius: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallpaper['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            wallpaper['author'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {
                        // Handle share action
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  wallpaper['description'],
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCircularActionButton(Icons.download, 'Download', () {
                      _downloadWallpaper(context);
                    }),
                    _buildCircularActionButton(
                      Icons.favorite_border,
                      'Like',
                      () {
                        // Handle like action
                      },
                    ),
                    _buildCircularActionButton(Icons.image, 'Set', () {
                      _showSetWallpaperDialog(context);
                    }),
                    _buildCircularActionButton(
                      Icons.info_outline,
                      'Info',
                      toggleMetadata,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Sliding Metadata Row
                Stack(
                  children: [
                    // Placeholder to maintain height during animation
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: SizedBox(
                        height:
                            showMetadata ? 60 : 0, // Adjust height dynamically
                      ),
                    ),
                    // Actual Metadata Row
                    if (showMetadata)
                      SlideTransition(
                        position: slideAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetadataBox(
                              'Downloads',
                              '${wallpaper['downloads']}',
                            ),
                            _buildMetadataBox(
                              'Resolution',
                              wallpaper['resolution'],
                            ),
                            _buildMetadataBox('Size', wallpaper['size']),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        ClipOval(
          child: Material(
            color: Colors.black.withOpacity(0.5), // Button background color
            child: IconButton(
              icon: Icon(icon, color: Colors.white),
              onPressed: onPressed,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildMetadataBox(String label, String value) {
    return Expanded(
      child: Container(
        height: 60, // Fixed height for consistent box sizes
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadWallpaper(BuildContext context) async {
    try {
      // Determine the directory based on the platform
      Directory bloomsplashDir;
      if (Platform.isLinux) {
        // Use a custom directory for Linux
        final homeDir = Platform.environment['HOME'] ?? Directory.current.path;
        bloomsplashDir = Directory('$homeDir/Downloads/bloomsplash');
      } else if (Platform.isAndroid) {
        // Use DCIM directory for Android
        final directory = Directory('/storage/emulated/0/DCIM/bloomsplash');
        bloomsplashDir = directory;
      } else if (Platform.isMacOS || Platform.isWindows) {
        // Use Downloads directory for macOS and Windows
        final downloadsDir = await getDownloadsDirectory();
        bloomsplashDir = Directory('${downloadsDir!.path}/bloomsplash');
      } else {
        // Use path_provider for other platforms
        final directory = await getApplicationDocumentsDirectory();
        bloomsplashDir = Directory('${directory.path}/bloomsplash');
      }

      // Create the bloomsplash folder if it doesn't exist
      if (!await bloomsplashDir.exists()) {
        await bloomsplashDir.create(recursive: true);
      }

      // Generate the file name
      final date = DateTime.now();
      final formattedDate =
          '${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}${date.year}';
      final fileName =
          '${wallpaper['name']}_${wallpaper['author']}_$formattedDate.jpg'
              .replaceAll(' ', '_');

      // File path
      final filePath = '${bloomsplashDir.path}/$fileName';

      // Check if the wallpaper path is a local asset or a URL
      if (wallpaper['image'].startsWith('http')) {
        // Download from URL
        final dio = Dio();
        await dio.download(
          wallpaper['image'], // URL
          filePath,
        );
      } else {
        // Load the local asset and save it to the file
        final byteData = await rootBundle.load(
          wallpaper['image'],
        ); // Load asset
        final file = File(filePath);
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }

      // Notify the media scanner (Android only)
      if (Platform.isAndroid) {
        try {
          final file = File(filePath);
          // Check if the file exists

          // Notify the MediaStore about the new file
          await MediaScanner.loadMedia(path: file.path);
          debugPrint('MediaStore notified about new file: $filePath');
        } catch (e) {
          debugPrint('Failed to notify MediaStore: $e');
        }
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wallpaper downloaded to $filePath')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download wallpaper: $e')),
        );
      }
    }
  }

  void _showSetWallpaperDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          true, // Allow dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor:
              Colors.transparent, // Make the dialog background transparent
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ), // Add blur effect
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(
                    0.7,
                  ), // Semi-transparent background
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Set Wallpaper',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose where to set the wallpaper:',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Full-width pill buttons
                    _buildPillButton(
                      context,
                      label: 'Home Screen',
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        _setWallpaper(
                          context,
                          WallpaperType.home,
                          wallpaper['image'],
                        ); // Set to home screen
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildPillButton(
                      context,
                      label: 'Lock Screen',
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        _setWallpaper(
                          context,
                          WallpaperType.lock,
                          wallpaper['image'],
                        ); // Set to lock screen
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildPillButton(
                      context,
                      label: 'Both',
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        _setWallpaper(
                          context,
                          WallpaperType.both,
                          wallpaper['image'],
                        ); // Set to both
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _setWallpaper(BuildContext context, WallpaperType type, String url) async {
    String result;
    bool goToHome = false; // Set to true or false based on your requirement

    try {
      // Determine the wallpaper location
      int wallpaperLocation;
      String target = 'Unknown'; // Default value for target
      switch (type) {
        case WallpaperType.home:
          wallpaperLocation = AsyncWallpaper.HOME_SCREEN;
          target = 'Home Screen';
          break;
        case WallpaperType.lock:
          wallpaperLocation = AsyncWallpaper.LOCK_SCREEN;
          target = 'Lock Screen';
          break;
        case WallpaperType.both:
          wallpaperLocation = AsyncWallpaper.BOTH_SCREENS;
          target = 'Both';
          break;
      }

      // Use the same logic as _downloadWallpaper to handle URL or asset
      final filePath = await _getFilePath(context, url);

      // Ensure the file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Wallpaper file does not exist at $filePath');
      }

      // Set the wallpaper
      result = await AsyncWallpaper.setWallpaperFromFile(
        filePath: file.path,
        wallpaperLocation: wallpaperLocation,
        goToHome: goToHome,
        toastDetails: ToastDetails.success(),
        errorToastDetails: ToastDetails.error(),
      )
          ? 'Wallpaper set'
          : 'Failed to set wallpaper.';
    } on PlatformException {
      result = 'Failed to set wallpaper.';
    } catch (e) {
      result = 'Error: $e';
    }

    // Show SnackBar for success or failure
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result == 'Wallpaper set'
              ? 'Wallpaper set to successfully!'
              : 'Failed to set wallpaper: $result'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildPillButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity, // Full width
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent, // Button color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0), // Pill shape
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0), // Button height
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<String> _getFilePath(BuildContext context, String url) async {
    try {
      // Determine the directory based on the platform
      Directory bloomsplashDir;
      if (Platform.isLinux) {
        final homeDir = Platform.environment['HOME'] ?? Directory.current.path;
        bloomsplashDir = Directory('$homeDir/Downloads/bloomsplash');
      } else if (Platform.isAndroid) {
        final directory = Directory('/storage/emulated/0/DCIM/bloomsplash');
        bloomsplashDir = directory;
      } else if (Platform.isMacOS | Platform.isWindows) {
        final downloadsDir = await getDownloadsDirectory();
        bloomsplashDir = Directory('${downloadsDir!.path}/bloomsplash');
      } else {
        final directory = await getApplicationDocumentsDirectory();
        bloomsplashDir = Directory('${directory.path}/bloomsplash');
      }

      // Create the bloomsplash folder if it doesn't exist
      if (!await bloomsplashDir.exists()) {
        await bloomsplashDir.create(recursive: true);
      }

      // Generate the file name
      final date = DateTime.now();
      final formattedDate =
          '${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}${date.year}';
      final fileName = '${wallpaper['name']}_${wallpaper['author']}_$formattedDate.jpg'
          .replaceAll(' ', '_');

      // File path
      final filePath = '${bloomsplashDir.path}/$fileName';
      File actualFile = File(filePath); // Initialize with a default value

      // Check if the wallpaper path is a local asset or a URL
      if (url.startsWith('http')) {
        // Download from URL
        final dio = Dio();
        await dio.download(url, filePath);
      } else {
        // Load the local asset and save it to the file
        final byteData = await rootBundle.load(url); // Load asset
        final file = File(filePath);
        await file.writeAsBytes(byteData.buffer.asUint8List());
        actualFile = file;
      }

      return actualFile.path;
    } catch (e) {
      throw Exception('Failed to get file path: $e');
    }
  }
}

enum WallpaperType { home, lock, both }
