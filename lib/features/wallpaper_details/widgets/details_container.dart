import 'package:flutter/material.dart';

import 'wallpaper_utils.dart';
import 'metadata_box.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../../../core/constant/config.dart';
import 'package:hive/hive.dart';


class DetailsContainer extends StatefulWidget {
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
  State<DetailsContainer> createState() => _DetailsContainerState();
}

class _DetailsContainerState extends State<DetailsContainer> {
  bool _isDownloading = false;
  Map<String, dynamic>? _wallpaperData;

  Future<void> _handleDownload(BuildContext context, String image, String? wallpaperId) async {
    setState(() {
      _isDownloading = true;
    });
    try {
      await downloadWallpaper(context, image, wallpaperId: wallpaperId);
      // Instantly update downloads count locally
      setState(() {
        final current = _wallpaperData ?? widget.wallpaper;
        final downloads = (current['downloads'] ?? current['download'] ?? 0);
        final newDownloads = (downloads is int)
            ? downloads + 1
            : int.tryParse(downloads.toString()) != null
                ? int.parse(downloads.toString()) + 1
                : 1;
        _wallpaperData = Map<String, dynamic>.from(current);
        _wallpaperData!['downloads'] = newDownloads;

        // Update Hive cache for this wallpaper
        try {
          // Open the box (adjust box name if needed)
          final box = Hive.box('uploadedWallpapers');
          // Find the wallpaper by id and update downloads
          final id = _wallpaperData!['id'] ?? widget.wallpaper['id'];
          final keys = box.keys.toList();
          for (var key in keys) {
            final item = box.get(key);
            if (item is Map && item['id'] == id) {
              final updated = Map<String, dynamic>.from(item);
              updated['downloads'] = newDownloads;
              box.put(key, updated);
              break;
            }
          }
        } catch (e) {
          debugPrint('Failed to update Hive cache for downloads: $e');
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallpaper = _wallpaperData ?? widget.wallpaper;
    final name = wallpaper['name'] ?? 'Untitled';
    final author = wallpaper['author'] ?? 'unknown author';
    final description = wallpaper['description'] ?? 'No description available';
    final authorImage =
        wallpaper['authorImage']?.startsWith('http') == true
            ? wallpaper['authorImage']
            : AppConfig.authorIconPath;
    final image = wallpaper['image'] ?? AppConfig.shimmerImagePath;
    final size = wallpaper['size'] ?? 'Unknown';
    final download = wallpaper['downloads']?.toString() ?? wallpaper['download']?.toString() ?? '0';
    final resolution = wallpaper['resolution'] ?? 'Unknown';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Always use semi-transparent black background
          color: Colors.black.withValues(alpha: 0.55),
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
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      buildCircularActionButton(
                        Icons.download,
                        'Download',
                        _isDownloading
                            ? null
                            : () {
                                _handleDownload(context, image, widget.wallpaper['id']);
                              },
                        disabled: _isDownloading,
                      ),
                      if (_isDownloading)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  buildCircularActionButton(
                    widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                    'Like',
                    () {
                      widget.toggleFavorite();
                    },
                    iconColor: widget.isFavorite ? Color(0xFFE91E63) : Colors.white, // Deep pink
                  ),
                  buildCircularActionButton(Icons.image, 'Set', () {
                    showSetWallpaperDialog(context, image);
                  }),
                  buildCircularActionButton(
                    Icons.info_outline,
                    'Info',
                    widget.toggleMetadata,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Stack(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: SizedBox(height: widget.showMetadata ? 60 : 0),
                  ),
                  if (widget.showMetadata)
                    SlideTransition(
                      position: widget.slideAnimation,
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
