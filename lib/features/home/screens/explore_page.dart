import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/wallpaper_card.dart';
import '../../../app/providers/favorites_provider.dart';
import '../../wallpaper_details/screens/wallpaper_details_page.dart';

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

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _lastDocument = snapshot.docs.last;
          if (isRefresh) {
            _wallpapers.clear(); // Clear only on refresh
          }
          _wallpapers.addAll(snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>));
        });
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
      body: RefreshIndicator(
        onRefresh: () => _fetchWallpapers(isRefresh: true),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(), // Snappy scrolling
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Number of cards per row
                  crossAxisSpacing: 8, // Horizontal spacing between cards
                  mainAxisSpacing: 8, // Vertical spacing between cards
                  childAspectRatio: 0.75, // Aspect ratio of the cards
                ),
                itemCount: _wallpapers.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _wallpapers.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
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
                      onFavoritePressed: () {
                        favoritesProvider.toggleFavorite(wallpaper);
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
