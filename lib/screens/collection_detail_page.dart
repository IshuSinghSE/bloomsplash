import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../features/wallpaper_details/screens/wallpaper_details_page.dart';
import '../app/constants/config.dart';
import '../core/themes/app_colors.dart';
import '../features/shared/widgets/custom_bottom_nav_bar.dart';

class CollectionDetailPage extends StatelessWidget {
  final String title;
  final String author;
  final List<Map<String, dynamic>> wallpapers;

  const CollectionDetailPage({
    super.key,
    required this.title,
    required this.wallpapers,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> wallpapersList = wallpapers.map((w) => Map<String, dynamic>.from(w)).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      extendBody: true,
      body: GridView.builder(
        physics: const BouncingScrollPhysics(),
        cacheExtent: 1000,
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: wallpapersList.length,
        itemBuilder: (context, index) {
          final wallpaper = wallpapersList[index];
          final image = wallpaper["image"] ?? AppConfig.shimmerImagePath;
          final name = wallpaper["name"] ?? "Untitled";
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WallpaperDetailsPage(wallpaper: wallpaper),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Stack(
                children: [
                  if (image.toString().startsWith('http'))
                    CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
                    )
                  else
                    Image.asset(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gradientStart,
                            AppColors.gradientEnd,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Text(
                      name,
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: const Icon(
                      Icons.auto_awesome_motion,
                      color: AppColors.accentSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 1, // Or whichever index is appropriate for navigation
        onItemTapped: (index) {}, // You may want to wire this up for navigation
      ),
    );
  }
}
