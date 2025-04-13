import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/data.dart'; // Import the wallpapers list

class WallpaperDetailsPage extends StatefulWidget {
  final int index; // Receive the index of the wallpaper

  const WallpaperDetailsPage({super.key, required this.index});

  @override
  State<WallpaperDetailsPage> createState() => _WallpaperDetailsPageState();
}

class _WallpaperDetailsPageState extends State<WallpaperDetailsPage> with SingleTickerProviderStateMixin {
  bool _showMetadata = false; // Track whether the metadata row is visible
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start off-screen
      end: Offset.zero, // Slide into view
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMetadata() {
    if (_animationController.isAnimating) return; // Prevent toggling during animation
    setState(() {
      if (_showMetadata) {
        _animationController.reverse(); // Slide out
      } else {
        _animationController.forward(); // Slide in
      }
      _showMetadata = !_showMetadata;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fetch the wallpaper data using the index
    final wallpaper = wallpapers[widget.index];

    return Scaffold(
      body: Stack(
        children: [
          // Full-Screen Wallpaper
          Image.asset(
            wallpaper['image'],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Navigate Back Icon with Blur Background
          Positioned(
            top: 16,
            left: 16,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context); // Navigate back
                    },
                  ),
                ),
              ),
            ),
          ),
          // Blurred Overlay for Details
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.6),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author Image, Wallpaper Title, and Description
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: AssetImage(wallpaper['authorImage']),
                              radius: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wallpaper['name'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 0),
                                  Text(
                                    wallpaper['author'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.white),
                              onPressed: () {
                                // Handle share action
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Description
                        Text(
                          wallpaper['description'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCircularActionButton(Icons.download, 'Download', () {
                              // Handle download action
                            }),
                            _buildCircularActionButton(Icons.favorite_border, 'Like', () {
                              // Handle like action
                            }),
                            _buildCircularActionButton(Icons.image, 'Set', () {
                              // Handle set action
                            }),
                            _buildCircularActionButton(Icons.info_outline, 'Info', _toggleMetadata),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Sliding Metadata Row with Placeholder
                        Stack(
                          children: [
                            // Placeholder to maintain height during animation
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: SizedBox(
                                height: _showMetadata ? 60 : 0, // Adjust height dynamically
                              ),
                            ),
                            // Actual Metadata Row
                            if (_showMetadata)
                              SlideTransition(
                                position: _slideAnimation,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildMetadataBox('Downloads', '${wallpaper['downloads']}'),
                                    _buildMetadataBox('Resolution', wallpaper['resolution']),
                                    _buildMetadataBox('Size', wallpaper['size']),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularActionButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        ClipOval(
          child: Material(
            color: Colors.black.withOpacity(0.5), // Button background color
            child: IconButton(
              icon: Icon(icon, color: Colors.white),
              onPressed: onPressed,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataBox(String label, String value) {
    return Expanded(
      child: Container(
        height: 60, // Fixed height for consistent box sizes
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}