import 'package:flutter/material.dart';
import 'wallpaper_details_page.dart';
// import '../constants/data.dart'; // Import the wallpapers list

class CollectionWallpapersPage extends StatelessWidget {
  final String title; // Title of the collection or category
  final String author; // Author of the wallpapers
  final List<Map<String, dynamic>> wallpapers; // Wallpapers to display

  const CollectionWallpapersPage({
    super.key,
    required this.title,
    required this.wallpapers,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of wallpapers per row
          crossAxisSpacing: 8, // Horizontal spacing
          mainAxisSpacing: 8, // Vertical spacing
          childAspectRatio: 0.75, // Aspect ratio of the grid items
        ),
        itemCount: wallpapers.length,
        itemBuilder: (context, index) {
          final wallpaper = wallpapers[index];
          final image =
              wallpaper["image"] ??
              "assets/sample/1744480267990.png"; // Fallback to sample image
          final name =
              wallpaper["name"] ?? "Untitled"; // Fallback to "Untitled"
         

          return GestureDetector(
            onTap: () {
              // Navigate to the wallpaper details page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          WallpaperDetailsPage( wallpaper: wallpaper), // Pass wallpaper ID and wallpaper object
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Wallpaper Image
                  if (image.isNotEmpty)
                    Image.asset(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: .6),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  // Wallpaper Title
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: const Icon(
                      Icons.auto_awesome_motion,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
