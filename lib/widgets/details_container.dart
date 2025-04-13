import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCircularActionButton(Icons.download, 'Download', () {
                      _downloadWallpaper(context);
                    }),
                    _buildCircularActionButton(Icons.favorite_border, 'Like', () {
                      // Handle like action
                    }),
                    _buildCircularActionButton(Icons.image, 'Set', () {
                      // Handle set action
                    }),
                    _buildCircularActionButton(Icons.info_outline, 'Info', toggleMetadata),
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
                        height: showMetadata ? 60 : 0, // Adjust height dynamically
                      ),
                    ),
                    // Actual Metadata Row
                    if (showMetadata)
                      SlideTransition(
                        position: slideAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetadataBox('Downloads', '${wallpaper['downloads']}'),
                            _buildMetadataBox('Resolution', wallpaper['resolution']),
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

  Widget _buildCircularActionButton(IconData icon, String label, VoidCallback onPressed) {
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
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
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
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
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
      Directory bloomspaceDir;
      if (Platform.isLinux) {
        // Use a custom directory for Linux
        final homeDir = Platform.environment['HOME'] ?? Directory.current.path;
        bloomspaceDir = Directory('$homeDir/bloomspace');
      } else {
        // Use path_provider for other platforms
        final directory = await getApplicationDocumentsDirectory();
        bloomspaceDir = Directory('${directory.path}/bloomspace');
      }

      // Create the bloomspace folder if it doesn't exist
      if (!await bloomspaceDir.exists()) {
        await bloomspaceDir.create(recursive: true);
      }

      // Generate the file name
      final date = DateTime.now();
      final formattedDate = '${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}${date.year}';
      final fileName = '${wallpaper['name']}_${wallpaper['author']}_$formattedDate.jpg'.replaceAll(' ', '_');

      // File path
      final filePath = '${bloomspaceDir.path}/$fileName';

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
        final byteData = await rootBundle.load(wallpaper['image']); // Load asset
        final file = File(filePath);
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wallpaper downloaded to $filePath')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download wallpaper: $e')),
      );
    }
  }
}