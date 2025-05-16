import 'package:flutter/material.dart';
import '../app/constants/data.dart'; // Import the dummy data
import 'collection_detail_page.dart'; // Import the collection wallpapers page
import '../app/constants/config.dart';
import '../core/themes/app_colors.dart'; // <-- Import the theme file

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  @override
  Widget build(BuildContext context) {  
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collections Sections
            ...collections.entries.map((entry) {
              final sectionTitle = entry.key;
              final sectionItems = entry.value;
              return _buildCollectionSection(sectionTitle, sectionItems);
            }),
            // Add bottom space
            const SizedBox(height: 80), // Adjust height as needed
          ],
        ),
      ),
    );
  }

  // Build a collection section { featured, curated, popular }
  // with a title and a list of wallpapers
  Widget _buildCollectionSection(
    String title,
    List<Map<String, dynamic>> wallpapers,
  ) {
    // If the collection's wallpapers are empty, use dummy wallpapers from local data
    final List<Map<String, dynamic>> displayWallpapers =
        (wallpapers.isNotEmpty && wallpapers[0]["wallpapers"] != null && (wallpapers[0]["wallpapers"] as List).isNotEmpty)
            ? wallpapers
            : List<Map<String, dynamic>>.from(collections.values.expand((c) => c).where((w) => w["image"] != null));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: 24, // Larger font size for section title
                    color: (title.toLowerCase().contains('trending')
                            ? Colors.amber
                            : title.toLowerCase().contains('popular')
                            ? Colors.cyanAccent
                            : title.toLowerCase().contains('monochrome')
                            ? Colors.orangeAccent
                            : Colors.white)
                        .withOpacity(0.82), // Reduced opacity
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CollectionDetailPage(
                          title: title,
                          author: wallpapers.isNotEmpty ? wallpapers[0]["author"] : "Unknown",
                          wallpapers: displayWallpapers,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: displayWallpapers.length > 5 ? 5 : displayWallpapers.length,
              separatorBuilder: (context, i) => const SizedBox(width: 16),
              itemBuilder: (context, i) {
                final wallpaper = displayWallpapers[i];
                final image = wallpaper["image"] ?? AppConfig.shimmerImagePath;
                final titleText = wallpaper["title"] ?? "Untitled";
                final author = wallpaper["author"] ?? "Unknown";
                final isLocked = wallpaper["isLocked"] == true;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CollectionDetailPage(
                          title: titleText,
                          author: author,
                          wallpapers: displayWallpapers,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1), // Subtle border
                        width: 1.2,
                      ),
                      image: DecorationImage(
                        image:
                            image.toString().startsWith('http')
                                ? NetworkImage(image)
                                : AssetImage(image) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: RadialGradient(
                                colors: [
                                  Colors.black.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                                center: Alignment.center,
                                radius: 1.0,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  titleText,
                                  style: AppTextStyles.cardTitle.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        offset: const Offset(0, 0),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'the essence of art',
                                  style: AppTextStyles.cardSubtitle.copyWith(
                                    color: Colors.grey[50],
                                    fontSize: 15,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        offset: const Offset(0, 0),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isLocked)
                          Positioned(
                            right: 18,
                            top: 18,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                      ],
                    ),
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
