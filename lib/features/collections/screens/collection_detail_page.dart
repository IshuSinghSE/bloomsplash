import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../wallpaper_details/screens/wallpaper_details_page.dart';
import '../../../core/constant/config.dart';
import '../../shared/widgets/fade_placeholder_image.dart';
import '../../../../models/collection_model.dart';
import '../../../app/services/firebase/collection_db.dart';
import '../../../core/themes/app_colors.dart';
import '../../shared/widgets/custom_bottom_nav_bar.dart';
import '../../home/screens/home_page.dart';

class CollectionDetailPage extends StatelessWidget {
  final String title;
  final String author;
  final Collection collection;
  final bool showBottomNav; 
  final int currentNavIndex; 

  const CollectionDetailPage({
    super.key,
    required this.title,
    required this.author,
    required this.collection,
    this.showBottomNav = true,
    this.currentNavIndex = 1,
  });

  void _onNavItemTapped(BuildContext context, int index) {
    if (index == currentNavIndex) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomePage(
          initialSelectedIndex: index,
          preferencesBox: Hive.box('preferences'),
        ),
      ),
      (route) => false,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchWallpapers() async {
    final service = CollectionService();
    final wallpapers = await service.getWallpapersForCollection(collection);
    return wallpapers.map((w) => w.toJson()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      extendBody: true,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchWallpapers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: 8,
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FadePlaceholderImage(path: AppConfig.shimmerImagePath),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading wallpapers'));
          }
          final wallpapersList = snapshot.data ?? [];
          if (wallpapersList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('🗂️', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Collection is empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 96.0),
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
                          placeholder: (context, url) => FadePlaceholderImage(path: AppConfig.shimmerImagePath),
                          errorWidget: (context, url, error) => FadePlaceholderImage(path: AppConfig.shimmerImagePath),
                        )
                      else
                        FadePlaceholderImage(path: image),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.transparent,
                                Colors.amber.withValues(alpha: 0.08),
                                Colors.purpleAccent.withValues(alpha: 0.10),
                                Colors.orangeAccent.withValues(alpha: 0.10),
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
