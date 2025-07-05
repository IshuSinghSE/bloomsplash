import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/providers/favorites_provider.dart';
import '../../../app/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../wallpaper_details/screens/wallpaper_details_page.dart';
import '../../../core/utils/image_cache_utils.dart';
import '../../../core/constant/config.dart';

class FavoritesPage extends StatelessWidget {
  final bool showAppBar;

  const FavoritesPage({super.key, this.showAppBar = false});

  Future<void> _cacheImages(List<Map<String, dynamic>> favoriteWallpapers) async {
    final imageUrls = <String>[];
    
    for (final wallpaper in favoriteWallpapers) {
      // Add thumbnail URL
      final thumbnailUrl = wallpaper['thumbnail'] as String?;
      if (thumbnailUrl != null && thumbnailUrl.startsWith('http')) {
        imageUrls.add(thumbnailUrl);
      }
      
      // Add full image URL for faster detail view loading
      final fullUrl = wallpaper['url'] as String?;
      if (fullUrl != null && fullUrl.startsWith('http')) {
        imageUrls.add(fullUrl);
      }
    }
    
    if (imageUrls.isNotEmpty) {
      await cacheImages(imageUrls);
      debugPrint('Cached ${imageUrls.length} favorite wallpaper images');
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoriteWallpapers = favoritesProvider.favorites.reversed.toList();
    final uid = authProvider.user?.uid;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Favorites'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                // Manual sync button
                Consumer<FavoritesProvider>(
                  builder: (context, favoritesProvider, child) {
                    return IconButton(
                      icon: favoritesProvider.hasPendingChanges
                          ? const Icon(Icons.sync_problem, color: Colors.orange)
                          : const Icon(Icons.sync, color: Colors.green),
                      tooltip: favoritesProvider.hasPendingChanges 
                          ? 'Sync pending...' 
                          : 'Synced',
                      onPressed: favoritesProvider.hasPendingChanges && uid != null
                          ? () async {
                              try {
                                await favoritesProvider.forceSyncNow(uid);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green[400]),
                                        const SizedBox(width: 8),
                                        const Text('Favorites synced!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green[800],
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.error, color: Colors.red[400]),
                                        const SizedBox(width: 8),
                                        const Text('Sync failed!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.red[800],
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          : null,
                    );
                  },
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          // Sync status indicator
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              if (favoritesProvider.hasPendingChanges) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange[900]?.withValues(alpha: 0.3),
                    border: Border.all(
                      color: Colors.orange[400]!.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[400]!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Syncing favorites...',
                        style: TextStyle(
                          color: Colors.orange[100],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Main content
          Expanded(
            child: RefreshIndicator(
        onRefresh: () async {
          // Refresh favorites using the same method as settings page
          if (uid != null) {
            // First, force sync any pending changes to Firestore (same as settings)
            if (favoritesProvider.hasPendingChanges) {
              try {
                debugPrint('Syncing pending changes before refresh...');
                await favoritesProvider.forceSyncNow(uid);
                debugPrint('Forced sync of pending changes before refresh completed');
                
                // Show feedback that pending changes were synced
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.cloud_done, color: Colors.blue[400]),
                        const SizedBox(width: 8),
                        const Text('Pending changes synced!'),
                      ],
                    ),
                    backgroundColor: Colors.blue[800],
                    duration: const Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                debugPrint('Error syncing pending changes before refresh: $e');
                // Show error but continue with refresh
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[400]),
                        const SizedBox(width: 8),
                        const Text('Sync warning - refreshing anyway'),
                      ],
                    ),
                    backgroundColor: Colors.orange[800],
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
            
            // Then just save current local favorites to Firestore (same as settings page)
            await favoritesProvider.saveFavoritesToFirestore(uid);
            final refreshedFavorites = favoritesProvider.favorites;
            await _cacheImages(refreshedFavorites);
          } else {
            // If not logged in, just cache existing favorites
            await _cacheImages(favoriteWallpapers);
          }
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
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: favoriteWallpapers.length,
                      itemBuilder: (context, index) {
                        final wallpaper = favoriteWallpapers[index];
                        final image = wallpaper['thumbnail'] ?? AppConfig.shimmerImagePath;
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
                                if (image.startsWith('http'))
                                   CachedNetworkImage(
                                    imageUrl: image,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) {
                                      return Image.asset(
                                        AppConfig.shimmerImagePath,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      );
                                    },
                                    )
                                else
                                  Image.asset(
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
                                            onPressed: () async {
                                              if (uid != null) {
                                                await favoritesProvider.toggleFavoriteWithSync(wallpaper, uid);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('You must be logged in to manage favorites.')),
                                                );
                                              }
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
          ),
        ],
      ),
    );
  }
}