import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../app/providers/favorites_provider.dart';
import '../../wallpaper_details/screens/wallpaper_details_page.dart';
import '../../../core/constant/config.dart';

class WallpaperCard extends StatefulWidget {
  final Map<String, dynamic> wallpaper;
  final VoidCallback onFavoritePressed; // Define the onFavoritePressed parameter
  final WidgetBuilder? imageBuilder; // Define the imageBuilder parameter

  const WallpaperCard({
    super.key,
    required this.wallpaper,
    required this.onFavoritePressed,
    this.imageBuilder,
  });

  @override
  State<WallpaperCard> createState() => _WallpaperCardState();
}

class _WallpaperCardState extends State<WallpaperCard> {
  Offset _overlayOffset = Offset.zero;

  void _handleTap() async {
    // Wait for the hero animation to finish before hiding the overlay
    
    if (!mounted) return;
    setState(() {
      _overlayOffset = const Offset(0, 1); // Slide fully down
    });
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => WallpaperDetailsPage(wallpaper: widget.wallpaper),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _overlayOffset = Offset.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? thumbnailUrl = widget.wallpaper['thumbnail'];
    final String heroTag = widget.wallpaper['id'] ?? thumbnailUrl ?? '';
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(widget.wallpaper);

    return GestureDetector(
      onTap: _handleTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Hero(
              tag: heroTag,
              child: widget.imageBuilder != null
                  ? widget.imageBuilder!(context)
                  : CachedNetworkImage(
                      imageUrl: thumbnailUrl ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Center(
                        child: Image.asset(
                          AppConfig.shimmerImagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset: _overlayOffset,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                widget.wallpaper['name'] ?? 'Untitled',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                widget.wallpaper['author'] ?? 'Unknown Author',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          favoritesProvider.toggleFavorite(widget.wallpaper);
                        },
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
