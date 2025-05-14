import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:shimmer/shimmer.dart';
import '../widgets/wallpaper_card.dart';
import '../../../app/providers/favorites_provider.dart';
import '../../../app/constants/config.dart';
// import '../../wallpaper_details/screens/wallpaper_details_page.dart';

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
  final int _loadedWallpapers = 50; // Number of wallpapers to load initially
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
      final query = FirebaseFirestore.instance
          .collection('wallpapers')
          .orderBy('createdAt', descending: true)
          .limit(_loadedWallpapers);

      QuerySnapshot snapshot;
      if (_lastDocument == null || isRefresh) {
        snapshot = await query.get();
      } else {
        snapshot = await query.startAfterDocument(_lastDocument!).get();
      }

      setState(() {
        if (isRefresh) {
          _wallpapers.clear(); // Clear on refresh regardless of result
        }
        
        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
          // Duplicate the fetched wallpapers 2 times for testing scroll smoothness
          final docs = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          for (int i = 0; i < 2; i++) {
            _wallpapers.addAll(docs);
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
        !_isLoadingMore) {
      _loadMoreWallpapers();
    }
  }

  Future<void> _loadMoreWallpapers() async {
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchWallpapers();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _fetchWallpapers(isRefresh: true),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _wallpapers.isEmpty
                ? Center(
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
                  )
                : GridView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    cacheExtent: 400, // Lower cacheExtent for minimal memory usage
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    addSemanticIndexes: false,
                    itemCount: _wallpapers.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _wallpapers.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final wallpaper = _wallpapers[index];
                      return WallpaperCard(
                        wallpaper: wallpaper,
                        onFavoritePressed: () {
                          favoritesProvider.toggleFavorite(wallpaper);
                        },
                        imageBuilder: (context) {
                          final String? thumbnailUrl = wallpaper['thumbnail'];
                          if (thumbnailUrl != null && thumbnailUrl.startsWith('http')) {
                            return CachedNetworkImage(
                              imageUrl: thumbnailUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              memCacheHeight: 200, // Lower memory usage for cache
                              memCacheWidth: 120,
                              maxWidthDiskCache: 240, // Disk cache for low-res
                              maxHeightDiskCache: 400,
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
                  ),
      ),
    );
  }
}
