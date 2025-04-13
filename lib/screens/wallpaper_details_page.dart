import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/data.dart'; // Import the wallpapers list
import '../widgets/details_container.dart'; // Import the new DetailsContainer widget

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
            top: 32,
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
            child: DetailsContainer(
              wallpaper: wallpaper,
              showMetadata: _showMetadata,
              slideAnimation: _slideAnimation,
              toggleMetadata: _toggleMetadata,
            ),
          ),
        ],
      ),
    );
  }
}