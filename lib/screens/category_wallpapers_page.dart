import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import 'wallpaper_details_page.dart';

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
      appBar: AppBar(
        title: Text(category),
      ),
      body: GridView.builder(
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
          final image = wallpaper["image"] ?? "assets/sample/1744480268028.png";
          final author = wallpaper["author"] ?? "Unknown";
          final title = wallpaper["name"] ?? "Untitled"; // Fallback to "Untitled"
          final id = wallpaper["id"] ?? "unknown-id"; // Fallback to a default ID

          return GestureDetector(
            onTap: () {
              // Navigate to the wallpaper details page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WallpaperDetailsPage(id: id), // Pass wallpaper ID
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Wallpaper Image
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
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                author,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Consumer<FavoritesProvider>(
                          builder: (context, favoritesProvider, child) {
                            final isFavorite = favoritesProvider.isFavorite(wallpaper);
                            return IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Colors.white,
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
                      color: Colors.white70,
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