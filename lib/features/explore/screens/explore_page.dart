import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/wallpaper_card.dart';
import '../../../app/providers/favorites_provider.dart';
import '../../../core/constant/config.dart';
import '../../../core/utils/image_cache_utils.dart';
import '../../../app/providers/auth_provider.dart';
import 'package:hive/hive.dart';
import '../../shared/widgets/fade_placeholder_image.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with AutomaticKeepAliveClientMixin {
  late final ScrollController _scrollController;
  final List<Map<String, dynamic>> _wallpapers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  final int _loadedWallpapers = 20;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchWallpapers(isRefresh: true);
    });
  }

  // Future<void> _loadWallpapersFromCache() async {
  //   // No-op: cache loading is not used for initial display anymore
  // }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchWallpapers({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _hasReachedEnd = false;
        _lastDocument = null;
      });
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection('wallpapers')
          .where('status', isEqualTo: 'approved')
          .where('collectionId', isNull: true)
          .orderBy('createdAt', descending: true)
          .limit(_loadedWallpapers);

      QuerySnapshot snapshot;
      if (isRefresh) {
        // Always fetch the latest wallpapers from Firestore, ignore cache and pagination
        snapshot = await query.get();
      } else if (_lastDocument == null) {
        snapshot = await query.get();
      } else {
        snapshot = await query.startAfterDocument(_lastDocument!).get();
      }

      setState(() {
        final fetchedWallpapers = snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {'id': doc.id, ...data};
            })
            .where((wallpaper) => wallpaper['status'] == 'approved')
            .toList();

        if (isRefresh) {
          // On refresh, fully replace _wallpapers with fetchedWallpapers
          _wallpapers
            ..clear()
            ..addAll(fetchedWallpapers);
          if (fetchedWallpapers.isNotEmpty) {
            _cacheNewWallpapers(fetchedWallpapers);
          }
        } else {
          // On paginated load, only add new wallpapers, never remove existing
          final existingIds = _wallpapers.map((w) => w['id']).toSet();
          final uniqueNewWallpapers =
              fetchedWallpapers.where((w) => !existingIds.contains(w['id'])).toList();
          _wallpapers.addAll(uniqueNewWallpapers);
          if (snapshot.docs.isNotEmpty) {
            _lastDocument = snapshot.docs.last;
          }
          if (snapshot.docs.length < _loadedWallpapers) {
            _hasReachedEnd = true;
          }
          if (uniqueNewWallpapers.isNotEmpty) {
            _cacheNewWallpapers(uniqueNewWallpapers);
          }
        }
      });
      // Save updated wallpapers to cache
      try {
        final box = await Hive.openBox('uploadedWallpapers');
        await box.put('wallpapers', _wallpapers);
      } catch (e) {
        debugPrint('Error saving wallpapers to cache: $e');
      }
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
    if (_hasReachedEnd || _isLoadingMore) return;

    final threshold = 6;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final itemHeight = maxScroll / ((_wallpapers.length > 0 ? _wallpapers.length : 1) / 2);
    if (maxScroll - currentScroll <= threshold * itemHeight) {
      _loadMoreWallpapers();
    }
  }

  Future<void> _loadMoreWallpapers() async {
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchWallpapers();
  }

  Future<void> _cacheNewWallpapers(
    List<Map<String, dynamic>> wallpapers,
  ) async {
    try {
      final imageUrls = <String>[];
      for (final wallpaper in wallpapers) {
        final thumbnailUrl = wallpaper['thumbnail'] as String?;
        if (thumbnailUrl != null && thumbnailUrl.startsWith('http')) {
          imageUrls.add(thumbnailUrl);
        }
        final fullUrl = wallpaper['url'] as String?;
        if (fullUrl != null && fullUrl.startsWith('http')) {
          imageUrls.add(fullUrl);
        }
      }
      if (imageUrls.isNotEmpty) {
        await cacheImages(imageUrls);
        debugPrint(
          'Cached ${imageUrls.length} new wallpaper images (thumbnails + full images)',
        );
      }
    } catch (e) {
      debugPrint('Error caching new wallpapers: $e');
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _fetchWallpapers(isRefresh: true),
        child:
            _isLoading
                ? CustomScrollView(
                  key: const PageStorageKey('explore_shimmer_scroll'),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(8.0),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.75,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return WallpaperCard(
                              wallpaper: {
                                'title': 'Loading...',
                                'author': '....',
                                'isFavorite': false,
                                'thumbnail': AppConfig.shimmerImagePath,
                                'url': '',
                                'status': 'approved',
                              },
                              onFavoritePressed: () {},
                              imageBuilder: (context) => FadePlaceholderImage(path: AppConfig.shimmerImagePath),
                            );
                          },
                          childCount: 8, // Show 8 shimmer placeholders
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: true,
                          addSemanticIndexes: false,
                        ),
                      ),
                    ),
                  ],
                )
                : _wallpapers.isEmpty
                ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pull down to refresh',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                : CustomScrollView(
                  key: const PageStorageKey('explore_scroll'),
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(8.0),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                                  await favoritesProvider
                                      .toggleFavoriteWithSync(wallpaper, uid);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'You must be logged in to favorite.',
                                      ),
                                    ),
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
                                    placeholder: (context, url) => FadePlaceholderImage(path: AppConfig.shimmerImagePath),
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
                    if (_hasReachedEnd && _wallpapers.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 16.0,
                          ),
                          margin: const EdgeInsets.only(bottom: 80.0),
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
                    // Removed loading indicator when scrolling
                  ],
                ),
      ),
    );
  }
}
