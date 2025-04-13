import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/wallpaper_details_page.dart';

class WallpaperCard extends StatelessWidget {
  final int index; // Pass the index of the wallpaper
  final String image;
  final String name;
  final String author;
  final VoidCallback onFavoritePressed;

  const WallpaperCard({
    super.key,
    required this.index,
    required this.image,
    required this.name,
    required this.author,
    required this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WallpaperDetailsPage(index: index), // Pass only the index
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Wallpaper Image
              Image.asset(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              // Wallpaper Details with Blur Background
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Wallpaper Name and Author
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis, // Truncate text
                                  maxLines: 1, // Ensure single line
                                ),
                                Text(
                                  author,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis, // Truncate text
                                  maxLines: 1, // Ensure single line
                                ),
                              ],
                            ),
                          ),
                          // Favorite Button
                          IconButton(
                            icon: const Icon(
                              Icons.favorite_border,
                              color: Colors.white,
                            ),
                            onPressed: onFavoritePressed,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}