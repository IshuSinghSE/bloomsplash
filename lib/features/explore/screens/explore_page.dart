import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:shimmer/shimmer.dart';
import '../widgets/wallpaper_card.dart';
import '../../../app/providers/favorites_provider.dart';
import '../../../core/constant/config.dart';
import '../../../core/utils/image_cache_utils.dart';
// import '../../wallpaper_details/screens/wallpaper_details_page.dart';
import '../../../app/providers/auth_provider.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _wallpapers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false; // Track if all wallpapers are loaded
  final int _loadedWallpapers = 10; // Number of wallpapers to load initially
  DocumentSnapshot? _lastDocument; // Track the last document for pagination

  @override
  void initState() {
    super.initState();
    _fetchWallpapers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchWallpapers({bool isRefresh = false}) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('wallpapers')
          .orderBy('createdAt', descending: true)
          .limit(_loadedWallpapers);

      QuerySnapshot snapshot;
      
      if (isRefresh) {
        // For refresh, get only NEW wallpapers that are newer than our newest wallpaper
        if (_wallpapers.isNotEmpty) {
          // Get the newest wallpaper's timestamp
          final newestWallpaper = _wallpapers.first;
          if (newestWallpaper['createdAt'] != null) {
            // Only fetch wallpapers newer than our newest one
            query = FirebaseFirestore.instance
                .collection('wallpapers')
                .orderBy('createdAt', descending: true)
                .where('createdAt', isGreaterThan: newestWallpaper['createdAt'])
                .limit(50); // Allow more for refresh to catch up
          }
        }
        snapshot = await query.get();
      } else if (_lastDocument == null) {
        // Initial load
        snapshot = await query.get();
      } else {
        // Load more (pagination)
        snapshot = await query.startAfterDocument(_lastDocument!).get();
      }

      setState(() {
        if (isRefresh) {
          // For refresh, ADD new wallpapers to the BEGINNING of the list
          final newWallpapers = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          
          // Add new wallpapers to the beginning, avoiding duplicates
          final existingIds = _wallpapers.map((w) => w['id']).toSet();
          final uniqueNewWallpapers = newWallpapers
              .where((wallpaper) => !existingIds.contains(wallpaper['id']))
              .toList();
          
          _wallpapers.insertAll(0, uniqueNewWallpapers);
          // Don't reset _hasReachedEnd on refresh - we're just adding to the top
          
          // Cache the new wallpapers' images
          if (uniqueNewWallpapers.isNotEmpty) {
            _cacheNewWallpapers(uniqueNewWallpapers);
          }
        } else {
          // For initial load or pagination, add to the end
          final newWallpapers = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          
          // Prevent duplicates by checking IDs
          final existingIds = _wallpapers.map((w) => w['id']).toSet();
          final uniqueNewWallpapers = newWallpapers
              .where((wallpaper) => !existingIds.contains(wallpaper['id']))
              .toList();
          
          _wallpapers.addAll(uniqueNewWallpapers);
          
          // Update _lastDocument for pagination
          if (snapshot.docs.isNotEmpty) {
            _lastDocument = snapshot.docs.last;
          }
          
          // Check if we've reached the end (no new wallpapers or less than requested)
          if (uniqueNewWallpapers.isEmpty || snapshot.docs.length < _loadedWallpapers) {
            _hasReachedEnd = true;
          }
          
          // Cache the new wallpapers' images
          if (uniqueNewWallpapers.isNotEmpty) {
            _cacheNewWallpapers(uniqueNewWallpapers);
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching wallpapers: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedEnd) {
      _loadMoreWallpapers();
    }
  }

  Future<void> _loadMoreWallpapers() async {
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchWallpapers();
  }

  /// Cache the images of new wallpapers for faster loading
  Future<void> _cacheNewWallpapers(List<Map<String, dynamic>> wallpapers) async {
    try {
      // Cache both thumbnail and full images for better user experience
      final imageUrls = <String>[];
      
      for (final wallpaper in wallpapers) {
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
        debugPrint('Cached ${imageUrls.length} new wallpaper images (thumbnails + full images)');
      }
    } catch (e) {
      debugPrint('Error caching new wallpapers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _fetchWallpapers(isRefresh: true),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _wallpapers.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7, // Ensures enough space to pull
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image_not_supported_rounded,
                              size: 70,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No wallpapers found',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pull down to refresh',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(8.0),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.75,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final wallpaper = _wallpapers[index];
                              return WallpaperCard(
                                wallpaper: wallpaper,
                                onFavoritePressed: () async {
                                  if (uid != null) {
                                    await favoritesProvider.toggleFavoriteWithSync(wallpaper, uid);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('You must be logged in to favorite.')),
                                    );
                                  }
                                },
                                imageBuilder: (context) {
                                  final String? thumbnailUrl = wallpaper['thumbnail'];
                                  if (thumbnailUrl != null && thumbnailUrl.startsWith('http')) {
                                    return CachedNetworkImage(
                                      imageUrl: thumbnailUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      useOldImageOnUrlChange: false,
                                      placeholder: (context, url) => Image.asset(
                                        AppConfig.shimmerImagePath,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                      errorWidget: (context, url, error) => const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                            childCount: _wallpapers.length,
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: true,
                            addSemanticIndexes: false,
                          ),
                        ),
                      ),
                      // Show "You've explored everything! 🎉" message when all wallpapers are loaded
                      if (_hasReachedEnd && _wallpapers.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                            margin: const EdgeInsets.only(bottom: 80.0), // Space above bottom nav bar
                            child: Center(
                              child: Text(
                                'You\'ve explored everything! 🎉',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Loading indicator when loading more
                      if (_isLoadingMore && !_hasReachedEnd)
                        SliverToBoxAdapter(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                            margin: const EdgeInsets.only(bottom: 80.0), // Space above bottom nav bar
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
