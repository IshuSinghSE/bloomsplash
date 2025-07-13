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
  final int _loadedWallpapers = 10;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadWallpapersFromCache();
  }

  Future<void> _loadWallpapersFromCache() async {
    try {
      final box = await Hive.openBox('uploadedWallpapers');
      final cached = box.get('wallpapers', defaultValue: []);
      if (cached is List && cached.isNotEmpty) {
        setState(() {
          _wallpapers.clear();
          _wallpapers.addAll(cached.map((w) => Map<String, dynamic>.from(w)).toList());
          _isLoading = false;
        });
      } else {
        _fetchWallpapers();
      }
    } catch (e) {
      debugPrint('Error loading wallpapers from cache: $e');
      _fetchWallpapers();
    }
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
        if (_wallpapers.isNotEmpty) {
          final newestWallpaper = _wallpapers.first;
          if (newestWallpaper['createdAt'] != null) {
            query = FirebaseFirestore.instance
                .collection('wallpapers')
                .orderBy('createdAt', descending: true)
                .where('createdAt', isGreaterThan: newestWallpaper['createdAt'])
                .limit(50);
          }
        }
        snapshot = await query.get();
      } else if (_lastDocument == null) {
        snapshot = await query.get();
      } else {
        snapshot = await query.startAfterDocument(_lastDocument!).get();
      }

      setState(() {
        if (isRefresh) {
          final newWallpapers =
              snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {'id': doc.id, ...data};
              })
              .where((wallpaper) => wallpaper['status'] == 'approved')
              .toList();
          final existingIds = _wallpapers.map((w) => w['id']).toSet();
          final uniqueNewWallpapers =
              newWallpapers
                  .where((wallpaper) => !existingIds.contains(wallpaper['id']))
                  .toList();
          _wallpapers.insertAll(0, uniqueNewWallpapers);
          if (uniqueNewWallpapers.isNotEmpty) {
            _cacheNewWallpapers(uniqueNewWallpapers);
          }
        } else {
          final newWallpapers =
              snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {'id': doc.id, ...data};
              })
              .where((wallpaper) => wallpaper['status'] == 'approved')
              .toList();
          final existingIds = _wallpapers.map((w) => w['id']).toSet();
          final uniqueNewWallpapers =
              newWallpapers
                  .where((wallpaper) => !existingIds.contains(wallpaper['id']))
                  .toList();
          _wallpapers.addAll(uniqueNewWallpapers);
          if (snapshot.docs.isNotEmpty) {
            _lastDocument = snapshot.docs.last;
          }
          if (uniqueNewWallpapers.isEmpty ||
              snapshot.docs.length < _loadedWallpapers) {
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
    if (!_isLoadingMore &&
        !_hasReachedEnd &&
        _wallpapers.length >= _loadedWallpapers) {
      final threshold = 6;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final itemHeight = maxScroll / (_wallpapers.length / 2);
      if (maxScroll - currentScroll <= threshold * itemHeight) {
        _loadMoreWallpapers();
      }
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
                ? const Center(child: CircularProgressIndicator())
                : _wallpapers.isEmpty
                ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
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
                                final String? thumbnailUrl =
                                    wallpaper['thumbnail'];
                                if (thumbnailUrl != null &&
                                    thumbnailUrl.startsWith('http')) {
                                  return CachedNetworkImage(
                                    imageUrl: thumbnailUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    useOldImageOnUrlChange: false,
                                    placeholder:
                                        (context, url) => Image.asset(
                                          AppConfig.shimmerImagePath,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                    errorWidget:
                                        (context, url, error) => const Center(
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
                    if (_isLoadingMore && !_hasReachedEnd)
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16.0,
                            horizontal: 16.0,
                          ),
                          margin: const EdgeInsets.only(bottom: 80.0),
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
