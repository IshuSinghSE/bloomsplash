import 'package:flutter/material.dart';
import '../constants/data.dart'; // Import the dummy data
import '../widgets/wallpaper_card.dart'; // Import the WallpaperCard widget

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Add the SearchBar at the top
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search wallpapers',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Expanded widget to ensure the GridView takes the remaining space
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Number of cards per row
                  crossAxisSpacing: 8, // Horizontal spacing between cards
                  mainAxisSpacing: 8, // Vertical spacing between cards
                  childAspectRatio: 0.75, // Aspect ratio of the cards
                ),
                itemCount: wallpapers.length, // Number of wallpapers
                itemBuilder: (context, index) {
                  final wallpaper = wallpapers[index];
                  return WallpaperCard(
                    index: index, // Pass the index
                    image: wallpaper['image'],
                    name: wallpaper['name'],
                    author: wallpaper['author'],
                    onFavoritePressed: () {
                      // Handle favorite button press
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}