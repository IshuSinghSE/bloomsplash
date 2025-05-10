import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/details_container.dart'; // Import the new DetailsContainer widget

class WallpaperDetailsPage extends StatefulWidget {
  final Map<String, dynamic> wallpaper; // Pass the wallpaper object

  const WallpaperDetailsPage({super.key, required this.wallpaper});

  @override
  State<WallpaperDetailsPage> createState() => _WallpaperDetailsPageState();
}

class _WallpaperDetailsPageState extends State<WallpaperDetailsPage> {
  bool _showDetails = true; // Track whether the details container is visible
  bool _showButtons = true; // Track whether the buttons are visible
  bool _showMetadata = false; // Track whether the metadata row is visible

  void _toggleMetadata() {
    setState(() {
      _showMetadata = !_showMetadata; // Toggle metadata visibility
    });
  }

  void _closeMetadata() {
    if (_showMetadata) {
      setState(() {
        _showMetadata = false; // Close metadata if it's open
      });
    }
  }

  void _toggleDetailsAndButtons() {
    setState(() {
      _showDetails = !_showDetails; // Toggle details container visibility
      _showButtons = _showDetails; // Ensure buttons visibility matches details
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    // Extract wallpaper details
    final wallpaper = widget.wallpaper;
    final String imageUrl = wallpaper['preview'] ?? '';
    // final String name = wallpaper['name'] ?? 'Untitled';
    // final String author = wallpaper['author'] ?? 'Unknown';

    // Check if the wallpaper is a favorite
    final isFavorite = favoritesProvider.isFavorite(wallpaper);

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            if (_showMetadata) {
              // If metadata is open, close it
              _closeMetadata();
            } else if (_showButtons && _showDetails) {
              // If metadata is closed and both buttons and details are visible, hide them
              _showButtons = false;
              _showDetails = false;
            } else {
              // Otherwise, show both buttons and details
              _showButtons = true;
              _showDetails = true;
            }
          });
        },
        child: Stack(
          children: [
            // Full-Screen Wallpaper
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
            // Navigate Back Icon with Blur Background
            if (_showButtons)
              Positioned(
                top: 32,
                left: 16,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Tooltip(
                      message: "Back", // Show label/hint on hover
                      child: Container(
                        color: Colors.black.withValues(alpha: .5),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context); // Navigate back
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Eye Icon to Toggle Details Visibility
            if (_showButtons)
              Positioned(
                top: 32,
                right: 16,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Tooltip(
                      message: "Preview", // Show label/hint on hover
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: IconButton(
                          icon: Icon(
                            _showDetails
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white,
                          ),
                          onPressed:
                              _toggleDetailsAndButtons, // Toggle details and buttons
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Animated Sliding Details Container
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {
                  // Prevent closing metadata when tapping inside the container
                },
                child: AnimatedSlide(
                  offset:
                      _showDetails
                          ? Offset.zero
                          : const Offset(0, 1), // Slide up or down
                  duration: const Duration(
                    milliseconds: 300,
                  ), // Animation duration
                  curve: Curves.easeInOut, // Smooth animation curve
                  child: DetailsContainer(
                    wallpaper: wallpaper,
                    showMetadata:
                        _showMetadata, // Pass metadata visibility state
                    slideAnimation: const AlwaysStoppedAnimation(
                      Offset.zero,
                    ), // No sliding animation for metadata
                    toggleMetadata: _toggleMetadata,
                    isFavorite: isFavorite,
                    toggleFavorite: () {
                      favoritesProvider.toggleFavorite(
                        wallpaper,
                      ); // Pass wallpaper object
                    }, // Pass toggle function
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
