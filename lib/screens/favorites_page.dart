import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../screens/wallpaper_details_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final favoriteWallpapers = favoritesProvider.favorites.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body:
          favoriteWallpapers.isEmpty
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Number of wallpapers per row
                            crossAxisSpacing: 8, // Horizontal spacing
                            mainAxisSpacing: 8, // Vertical spacing
                            childAspectRatio:
                                0.75, // Aspect ratio of the grid items
                          ),
                      itemCount: favoriteWallpapers.length,
                      itemBuilder: (context, index) {
                        final wallpaper = favoriteWallpapers[index];
                        final image =
                            wallpaper['image'] ??
                            'assets/sample/1744480268028.png';
                        // final name = wallpaper['name'] ?? 'Untitled';
                        final author = wallpaper['author'] ?? 'Unknown';
                        final title =
                            wallpaper['title'] ??
                            'Untitled'; // Fallback to "Untitled"

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),

                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => WallpaperDetailsPage(
                                        id: wallpaper['id'],
                                      ), // Pass wallpaper ID
                                ),
                              );
                            },

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
                                // Wallpaper Title
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  right: 8,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                        builder: (
                                          context,
                                          favoritesProvider,
                                          child,
                                        ) {
                                          final isFavorite = favoritesProvider
                                              .isFavorite(wallpaper);
                                          return IconButton(
                                            icon: Icon(
                                              isFavorite
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              favoritesProvider.toggleFavorite(
                                                wallpaper,
                                              );
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
    );
  }
}
