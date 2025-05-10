import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/data.dart'; // Import the wallpapers data
import '../widgets/wallpaper_card.dart'; // Import the WallpaperCard widget
import '../providers/favorites_provider.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    // Debugging: Print the wallpapers list to ensure it's valid
    // print(wallpapers);

    return Scaffold(
      body: CustomScrollView(
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
                  final wallpaper =
                      wallpapers[index]; // Fetch the wallpaper object
                  return WallpaperCard(
                    wallpaper: wallpaper, // Pass the entire wallpaper object
                    onFavoritePressed: () {
                      favoritesProvider.toggleFavorite(
                        wallpaper,
                      ); // Toggle favorite state
                    },
                  );
                },
                childCount: wallpapers.length, // Number of wallpapers
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '✨ end of the exploring...',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 16,
                    color: const Color.fromARGB(
                      255,
                      246,
                      251,
                      255,
                    ).withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
