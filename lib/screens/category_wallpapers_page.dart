import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app/providers/favorites_provider.dart';
import '../features/wallpaper_details/screens/wallpaper_details_page.dart';
import '../app/constants/config.dart';
import '../core/themes/app_colors.dart'; // <-- Import the theme file

class CategoryWallpapersPage extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> wallpapers;

  const CategoryWallpapersPage({
    super.key,
    required this.category,
    required this.wallpapers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
        physics: const BouncingScrollPhysics(),
        cacheExtent: 1000,
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of wallpapers per row
          crossAxisSpacing: 8, // Horizontal spacing
          mainAxisSpacing: 8, // Vertical spacing
          childAspectRatio: 0.75, // Aspect ratio of the grid items
        ),
        itemCount: wallpapers.length,
        itemBuilder: (context, index) {
          final wallpaper = wallpapers[index];
          final image = wallpaper["image"] ?? AppConfig.shimmerImagePath;
          final author = wallpaper["author"] ?? "Unknown";
          final title =
              wallpaper["name"] ?? "Untitled"; // Fallback to "Untitled"

          return GestureDetector(
            onTap: () {
              // Navigate to the wallpaper details page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          WallpaperDetailsPage(wallpaper: wallpaper), // Pass wallpaper and ID
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Stack(
                children: [
                  // Wallpaper Image
                  if (image.startsWith('http'))
                    CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
                    )
                  else
                    Image.asset(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gradientStart,
                            AppColors.gradientEnd,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  // Wallpaper Title and Favorite Button
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                author,
                                style: AppTextStyles.cardSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Consumer<FavoritesProvider>(
                          builder: (context, favoritesProvider, child) {
                            final isFavorite = favoritesProvider.isFavorite(
                              wallpaper,
                            );
                            return IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: AppColors.accent,
                              ),
                              onPressed: () {
                                favoritesProvider.toggleFavorite(wallpaper);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: const Icon(
                      Icons.category,
                      color: AppColors.accentSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
