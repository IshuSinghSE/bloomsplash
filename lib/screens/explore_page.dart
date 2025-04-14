import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/data.dart'; // Import the dummy data
import '../widgets/wallpaper_card.dart'; // Import the WallpaperCard widget
import '../providers/favorites_provider.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

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
                  final wallpaper = wallpapers[index];
                  return WallpaperCard(
                    index: index, // Pass the index
                    image: wallpaper['image'],
                    name: wallpaper['name'],
                    author: wallpaper['author'],
                    onFavoritePressed: () {
                      favoritesProvider.toggleFavorite(index); // Toggle favorite state
                    },
                  );
                },
                childCount: wallpapers.length, // Number of wallpapers
              ),
            ),
          ),
        ],
      ),
    );
  }
}