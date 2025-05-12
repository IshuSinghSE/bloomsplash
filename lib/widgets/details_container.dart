import 'dart:ui';
import 'package:flutter/material.dart';
import 'wallpaper_utils.dart' show downloadWallpaper, showSetWallpaperDialog;
import 'metadata_box.dart' show buildMetadataBox;
import 'shared_widgets.dart' show buildCircularActionButton;
import '../providers/favorites_provider.dart';
import 'package:provider/provider.dart';
import '../core/constants/config.dart';

class DetailsContainer extends StatelessWidget {
  final Map<String, dynamic> wallpaper;
  final bool showMetadata;
  final Animation<Offset> slideAnimation;
  final VoidCallback toggleMetadata;
  final bool isFavorite; // Add a property to track the favorite state
  final VoidCallback toggleFavorite; // Add a callback to toggle the favorite state

  const DetailsContainer({
    super.key,
    required this.wallpaper,
    required this.showMetadata,
    required this.slideAnimation,
    required this.toggleMetadata,
    required this.isFavorite, // Pass the favorite state
    required this.toggleFavorite, // Pass the toggle callback
  });

  @override
  Widget build(BuildContext context) {
    final name = wallpaper['name'] ?? 'Untitled';
    final author = wallpaper['author'] ?? 'unknown author';
    final description = wallpaper['description'] ?? 'No description available';
    final authorImage = wallpaper['authorImage']?.startsWith('http') == true
        ? wallpaper['authorImage']
        : AppConfig.authorIconPath1; // Ensure the correct asset path
    final image = wallpaper['image'] ?? AppConfig.placeholderImagePath;
    final size = wallpaper['size'] ?? 'Unknown';
    final download = wallpaper['download'] ?? '0';
    final resolution = wallpaper['resolution'] ?? 'Unknown';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Container(
            width: double.infinity,
            color: Colors.black.withAlpha(153),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author Image, Wallpaper Title, and Description
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: authorImage.startsWith('http')
                          ? NetworkImage(authorImage)
                          : AssetImage(authorImage) as ImageProvider,
                      radius: 24,
                      onBackgroundImageError: (_, __) {
                        debugPrint('Error loading author image: $authorImage');
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            author,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // IconButton(
                    //   icon: const Icon(Icons.share, color: Colors.white),
                    //   onPressed: () {
                    //     // Handle share action
                    //   },
                    // ),
                  ],
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    buildCircularActionButton(Icons.download, 'Download', () {
                      downloadWallpaper(context, image);
                    }),
                    buildCircularActionButton(
                      FavoritesProvider().isFavorite(wallpaper) ? Icons.favorite : Icons.favorite_border,
                      'Like',
                      () => Provider.of<FavoritesProvider>(context, listen: false).toggleFavorite(wallpaper), // Use the toggleFavorite callback
                    ),
                    buildCircularActionButton(Icons.image, 'Set', () {
                      showSetWallpaperDialog(context, image);
                    }),
                    buildCircularActionButton(
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
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: SizedBox(height: showMetadata ? 60 : 0),
                    ),
                    if (showMetadata)
                      SlideTransition(
                        position: slideAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            buildMetadataBox(
                              'Downloads',
                              download,
                            ),
                            buildMetadataBox(
                              'Resolution',
                              resolution,
                            ),
                            buildMetadataBox(
                              'Size',
                              size != null
                                  ? '${((int.tryParse(size.toString()) ?? 0) / (1024 * 1024)).toStringAsFixed(2)} MB'
                                  : 'Unknown',
                            ),
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
}
