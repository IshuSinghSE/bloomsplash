import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/data.dart'; // Import the wallpapers data
import '../widgets/wallpaper_card.dart'; // Import the WallpaperCard widget
import '../providers/favorites_provider.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final ScrollController _scrollController = ScrollController();
  int _loadedWallpapers = 20; // Initial number of wallpapers to load
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

    // Simulate a delay for loading more wallpapers
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _loadedWallpapers += 10; // Load 10 more wallpapers
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    return Scaffold(
      body: CustomScrollView(
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
                  if (index >= wallpapers.length) return null;
                  final wallpaper = wallpapers[index];
                  return WallpaperCard(
                    wallpaper: wallpaper,
                    onFavoritePressed: () {
                      favoritesProvider.toggleFavorite(wallpaper);
                    },
                  );
                },
                childCount: _loadedWallpapers.clamp(0, wallpapers.length),
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
            if (_loadedWallpapers >= wallpapers.length)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text("No more wallpapers to load"),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 80), 
              
              // Add some space at the end
            ),
        ],
      ),
    );
  }
}
