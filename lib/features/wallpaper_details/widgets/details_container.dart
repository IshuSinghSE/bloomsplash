import 'dart:ui';
import 'package:flutter/material.dart';
import 'wallpaper_utils.dart';
import 'metadata_box.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../../../core/constant/config.dart';

class DetailsContainer extends StatelessWidget {
  final Map<String, dynamic> wallpaper;
  final bool showMetadata;
  final Animation<Offset> slideAnimation;
  final VoidCallback toggleMetadata;
  final bool isFavorite;
  final VoidCallback toggleFavorite;

  const DetailsContainer({
    super.key,
    required this.wallpaper,
    required this.showMetadata,
    required this.slideAnimation,
    required this.toggleMetadata,
    required this.isFavorite,
    required this.toggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final name = wallpaper['name'] ?? 'Untitled';
    final author = wallpaper['author'] ?? 'unknown author';
    final description = wallpaper['description'] ?? 'No description available';
    final authorImage =
        wallpaper['authorImage']?.startsWith('http') == true
            ? wallpaper['authorImage']
            : AppConfig.authorIconPath1;
    final image = wallpaper['image'] ?? AppConfig.shimmerImagePath;
    final size = wallpaper['size'] ?? 'Unknown';
    final download = wallpaper['download'] ?? '0';
    final resolution = wallpaper['resolution'] ?? 'Unknown';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Always use semi-transparent black background
          color: Colors.black.withOpacity(0.55),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        authorImage.startsWith('http')
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
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildCircularActionButton(Icons.download, 'Download', () {
                    downloadWallpaper(context, image);
                  }),
                  buildCircularActionButton(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    'Like',
                    () {
                      // Use the passed toggleFavorite callback for correct state update
                      toggleFavorite();
                    },
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
              Stack(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: SizedBox(height: showMetadata ? 60 : 0),
                  ),
                  if (showMetadata)
                    SlideTransition(
                      position: slideAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          buildMetadataBox('Downloads', download),
                          buildMetadataBox('Resolution', resolution),
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
    );
  }
}
