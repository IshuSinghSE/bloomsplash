import 'package:flutter/material.dart';
import '../../../models/wallpaper_model.dart';

class WallpaperPage extends StatelessWidget {
  final Wallpaper wallpaper;

  const WallpaperPage({super.key, required this.wallpaper});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(wallpaper.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            wallpaper.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallpaper.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Category: ${wallpaper.category}'),
                const SizedBox(height: 8),
                Text('Resolution: ${wallpaper.resolution}'),
                const SizedBox(height: 8),
                Text('Downloads: ${wallpaper.downloads}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
