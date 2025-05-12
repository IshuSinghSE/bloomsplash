import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Import cache manager
import '../providers/favorites_provider.dart';
import '../screens/wallpaper_details_page.dart';
import '../utils/image_cache_utils.dart'; // Import the utility file
import '../core/constants/config.dart';
class FavoritesPage extends StatelessWidget {
  final bool showAppBar;

  const FavoritesPage({super.key, this.showAppBar = false});

  Future<void> _cacheImages(List<Map<String, dynamic>> favoriteWallpapers) async {
    final imageUrls = favoriteWallpapers
        .map((wallpaper) => wallpaper['image'])
        .whereType<String>()
        .toList();
    await cacheImages(imageUrls); // Use the utility function
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final favoriteWallpapers = favoritesProvider.favorites.reversed.toList();

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Favorites'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          await _cacheImages(favoriteWallpapers); // Cache images locally
        },
        child: favoriteWallpapers.isEmpty
            ? const Center(
                child: Text(
                  'No favorites added yet!',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Number of wallpapers per row
                        crossAxisSpacing: 8, // Horizontal spacing
                        mainAxisSpacing: 8, // Vertical spacing
                        childAspectRatio: 0.75, // Aspect ratio of the grid items
                      ),
                      itemCount: favoriteWallpapers.length,
                      itemBuilder: (context, index) {
                        final wallpaper = favoriteWallpapers[index];
                        final image = wallpaper['image'] ?? AppConfig.placeholderImagePath;
                        final author = wallpaper['author'] ?? 'Unknown';
                        final title = wallpaper['title'] ?? 'Untitled';

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WallpaperDetailsPage(wallpaper: wallpaper),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Image.network(
                                  image,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withAlpha(153),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                    ),
                                  ),
                                ),
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
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 70),
                ],
              ),
      ),
    );
  }
}
