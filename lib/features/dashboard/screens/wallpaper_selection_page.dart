import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../models/wallpaper_model.dart';

class WallpaperSelectionPage extends StatefulWidget {
  final List<Wallpaper> availableWallpapers;
  
  const WallpaperSelectionPage({
    super.key,
    required this.availableWallpapers,
  });

  @override
  State<WallpaperSelectionPage> createState() => _WallpaperSelectionPageState();
}

class _WallpaperSelectionPageState extends State<WallpaperSelectionPage> {
  final Set<Wallpaper> _selectedWallpapers = {};
  String _searchQuery = '';
  List<Wallpaper> _filteredWallpapers = [];
  
  @override
  void initState() {
    super.initState();
    _filteredWallpapers = widget.availableWallpapers;
  }
  
  void _filterWallpapers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredWallpapers = widget.availableWallpapers;
      } else {
        _filteredWallpapers = widget.availableWallpapers
            .where((w) => 
                w.name.toLowerCase().contains(query.toLowerCase()) ||
                w.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())) ||
                w.category.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
  
  void _toggleWallpaperSelection(Wallpaper wallpaper) {
    setState(() {
      if (_selectedWallpapers.contains(wallpaper)) {
        _selectedWallpapers.remove(wallpaper);
      } else {
        _selectedWallpapers.add(wallpaper);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Wallpapers'),
        actions: [
          TextButton.icon(
            onPressed: _selectedWallpapers.isEmpty 
                ? null 
                : () {
                    Navigator.pop(context, _selectedWallpapers.toList());
                  },
            icon: const Icon(Icons.check),
            label: Text('Add ${_selectedWallpapers.length}'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search wallpapers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
              onChanged: _filterWallpapers,
            ),
          ),
          Expanded(
            child: _filteredWallpapers.isEmpty
                ? const Center(
                    child: Text('No wallpapers match your search'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _filteredWallpapers.length,
                    itemBuilder: (context, index) {
                      final wallpaper = _filteredWallpapers[index];
                      final isSelected = _selectedWallpapers.contains(wallpaper);
                      return GestureDetector(
                        onTap: () => _toggleWallpaperSelection(wallpaper),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: wallpaper.thumbnailUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: wallpaper.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image, size: 48),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, size: 48),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                child: Text(
                                  wallpaper.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}