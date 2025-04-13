import 'package:flutter/material.dart';
import '../constants/data.dart'; // Import the dummy data
import '../widgets/wallpaper_card.dart'; // Import the WallpaperCard widget

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Add a SearchBar with dynamic visibility on scroll
          // SliverAppBar(
          //   pinned: true,
          //   floating: false,
          //   expandedHeight: 60.0,
          //   flexibleSpace: FlexibleSpaceBar(
          //     background: Container(
          //       padding: const EdgeInsets.all(8.0),
                
          //       // child: const TextField(
          //       //   decoration: InputDecoration(
          //       //     hintText: 'Search wallpapers',
          //       //     prefixIcon: Icon(Icons.search),
          //       //     border: OutlineInputBorder(),
          //       //   ),
          //       // ),
          //     ),
          //   ),
          // ),
          // SliverGrid to display the wallpapers
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
                      // Handle favorite button press
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