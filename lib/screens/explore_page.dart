import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../widgets/wallpaper_card.dart'; // Import the WallpaperCard widget
import '../providers/favorites_provider.dart';
import 'wallpaper_details_page.dart'; // Import the WallpaperDetailsPage

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final ScrollController _scrollController = ScrollController();
  final BaseCacheManager _cacheManager = DefaultCacheManager(); // Cache manager instance
  final List<Map<String, dynamic>> _wallpapers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final int _loadedWallpapers = 20; // Number of wallpapers to load initially
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
    _cacheManager.emptyCache(); // Optionally clear cache on dispose
    super.dispose();
  }

  Future<void> _fetchWallpapers() async {
    try {
      final query = FirebaseFirestore.instance
          .collection('wallpapers')
          .orderBy('createdAt', descending: true)
          .limit(_loadedWallpapers);

      QuerySnapshot snapshot;
      if (_lastDocument == null) {
        snapshot = await query.get();
      } else {
        snapshot = await query.startAfterDocument(_lastDocument!).get();
      }

      if (snapshot.docs.isNotEmpty) {
        debugPrint('Fetched ${snapshot.docs.length} wallpapers from Firestore.');
        setState(() {
          _lastDocument = snapshot.docs.last;
          _wallpapers.addAll(snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['thumbnail'] != null && data['thumbnail'].startsWith('http')) {
              return data;
            } else {
              debugPrint('Invalid thumbnail URL: ${data['thumbnail']}');
              return null;
            }
          }).whereType<Map<String, dynamic>>());
        });
      } else {
        debugPrint('No wallpapers found in Firestore.');
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(8.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Number of cards per row
                      crossAxisSpacing: 8, // Horizontal spacing between cards
                      mainAxisSpacing: 8, // Vertical spacing between cards
                      childAspectRatio: 0.75, // Aspect ratio of the cards
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= _wallpapers.length) return null;
                        final wallpaper = _wallpapers[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WallpaperDetailsPage(wallpaper: wallpaper),
                              ),
                            );
                          },
                          child: WallpaperCard(
                            wallpaper: wallpaper,
                            // cacheManager: _cacheManager, // Pass cache manager
                            onFavoritePressed: () {
                              favoritesProvider.toggleFavorite(wallpaper);
                            },
                          ),
                        );
                      },
                      childCount: _wallpapers.length,
                    ),
                  ),
                ),
                if (_isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                if (!_isLoadingMore && _wallpapers.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text("No wallpapers available"),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80), // Add some space at the end
                ),
              ],
            ),
    );
  }
}
