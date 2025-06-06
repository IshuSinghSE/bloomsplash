import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../app/providers/favorites_provider.dart';
import '../../wallpaper_details/screens/wallpaper_details_page.dart';
import '../../../core/constant/config.dart';

class WallpaperCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final String? thumbnailUrl = wallpaper['thumbnail'];
    final String heroTag = wallpaper['id'] ?? thumbnailUrl ?? '';
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(wallpaper);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => WallpaperDetailsPage(wallpaper: wallpaper),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              imageBuilder != null
                  ? imageBuilder!(context)
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
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
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
                            Text(
                              wallpaper['name'] ?? 'Untitled',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              wallpaper['author'] ?? 'Unknown Author',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          favoritesProvider.toggleFavorite(wallpaper);
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
            ],
          ),
        ),
      ),
    );
  }
}
