import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
// import 'package:android_content_provider/android_content_provider.dart'; // Add this package for MediaStore API
import 'package:media_scanner/media_scanner.dart'; // Add this package for MediaScanner


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
      barrierDismissible: true, // Allow dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Make the dialog background transparent
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Add blur effect
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7), // Semi-transparent background
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
                        _setWallpaper(context, WallpaperType.home); // Set to home screen
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildPillButton(
                      context,
                      label: 'Lock Screen',
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        _setWallpaper(context, WallpaperType.lock); // Set to lock screen
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildPillButton(
                      context,
                      label: 'Both',
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        _setWallpaper(context, WallpaperType.both); // Set to both
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

  Future<void> _setWallpaper(BuildContext context, WallpaperType type) async {
    // try {
      // String target;
      // int location;

      // Determine the target and location
      // switch (type) {
      //   case WallpaperType.home:
      //     target = 'Home Screen';
      //     location = WallpaperManagerFlutter.HOME_SCREEN;
      //     break;
      //   case WallpaperType.lock:
      //     target = 'Lock Screen';
      //     location = WallpaperManagerFlutter.LOCK_SCREEN;
      //     break;
      //   case WallpaperType.both:
      //     target = 'Both';
      //     location = WallpaperManagerFlutter.BOTH_SCREENS;
      //     break;
      // }

      // Get the file path of the current wallpaper
      // final filePath = 'https://img-s-msn-com.akamaized.net/tenant/amp/entityid/BB1msFQz?w=0&h=0&q=60&m=6&f=jpg&u=t'; // Use the current wallpaper's file path or URL

      // Check if the file is a URL or a local file
    //   String localFilePath;
    //   if (filePath.startsWith('http')) {
    //     // Download the file to a temporary directory
    //     final tempDir = await getTemporaryDirectory();
    //     final tempFilePath = '${tempDir.path}/${wallpaper['name']}.jpg';
    //     final dio = Dio();
    //     await dio.download(filePath, tempFilePath);
    //     localFilePath = tempFilePath;
    //   } else if (filePath.startsWith('assets/')) {
    //     // Load the local asset and save it to a temporary directory
    //     final tempDir = await getTemporaryDirectory();
    //     final tempFilePath = '${tempDir.path}/${wallpaper['name']}.jpg';
    //     final byteData = await rootBundle.load(filePath); // Load asset
    //     final file = File(tempFilePath);
    //     await file.writeAsBytes(byteData.buffer.asUint8List());
    //     localFilePath = tempFilePath;
    //   } else {
    //     // Use the local file path directly
    //     localFilePath = filePath;
    //   }

    //   // Ensure the file exists
    //   final file = File(localFilePath);
    //   if (!await file.exists()) {
    //     throw Exception('Wallpaper file does not exist at $localFilePath');
    //   }

    //   // Set the wallpaper
    //  await WallpaperManagerFlutter().setwallpaperfromFile(file, location);

    //   // if (!result) {
    //   //   // throw Exception('Failed to set wallpaper');
    //   //   ScaffoldMessenger.of(context).showSnackBar(
    //   //   const SnackBar(
    //   //     content: Text('Wallpaper NOT set successfully!'),
    //   //     duration: Duration(seconds: 2),
    //   //   ),
    //   // );
    //   // }
      // show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallpaper set successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

    //   // Show success message
    //   if (context.mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text('Wallpaper set to $target'),
    //         duration: const Duration(seconds: 2),
    //       ),
    //     );
    //   }
    // } catch (e) {
    //   // Check if context is still mounted before showing error message
    //   if (context.mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text('Failed to set wallpaper: $e'),
    //         duration: const Duration(seconds: 2),
    //       ),
    //     );
    //   }
    // }
  }

  Widget _buildPillButton(BuildContext context, {required String label, required VoidCallback onPressed}) {
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

enum WallpaperType { home, lock, both }
