import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../wallpaper_details/screens/wallpaper_details_page.dart';
import '../../../core/constant/config.dart';
import '../../../core/themes/app_colors.dart';
import '../../shared/widgets/custom_bottom_nav_bar.dart';
import '../../../main.dart';

class CollectionDetailPage extends StatelessWidget {
  final String title;
  final String author;
  final List<Map<String, dynamic>> wallpapers;
  final bool showBottomNav; // Control whether to show bottom nav
  final int currentNavIndex; // Current index for bottom nav

  const CollectionDetailPage({
    super.key,
    required this.title,
    required this.wallpapers,
    required this.author,
    this.showBottomNav = true,
    this.currentNavIndex = 1, // Default to Collections tab
  });

  void _onNavItemTapped(BuildContext context, int index) {
    if (index == currentNavIndex) {
      // Already on this tab, do nothing
      return;
    }

    // Clear all routes and navigate to home with the selected index
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomePage(
          initialSelectedIndex: index,
          preferencesBox: Hive.box('preferences'),
        ),
      ),
      (route) => false, // Remove all routes from the stack
    );
  }

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
      body: wallpapersList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('🗂️', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Collection is empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : GridView.builder(
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
                final image = wallpaper["thumbnail"] ?? AppConfig.shimmerImagePath;
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
                            placeholder: (context, url) => Image.asset(
                              AppConfig.shimmerImagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                            ),
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
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.transparent,
                                  Colors.amber.withOpacity(0.08),
                                  Colors.purpleAccent.withOpacity(0.10),
                                  Colors.orangeAccent.withOpacity(0.10),
                                ],
                                stops: const [0.0, 0.5, 0.8, 1.0],
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
      bottomNavigationBar: showBottomNav
          ? CustomBottomNavBar(
              selectedIndex: currentNavIndex,
              onItemTapped: (index) => _onNavItemTapped(context, index),
            )
          : null,
    );
  }
}
