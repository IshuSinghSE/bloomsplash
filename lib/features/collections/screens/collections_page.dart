import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/services/firebase/collection_db.dart';
import '../../../../models/collection_model.dart';
import 'collection_detail_page.dart'; // Import the collection wallpapers page
import 'collection_list_page.dart'; // Import the new collection list page

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  final CollectionService _collectionService = CollectionService();
  List<Collection> _collections = [];

  @override
  void initState() {
    super.initState();
    _fetchCollections();
  }

  Future<void> _fetchCollections() async {
    // Try to load from Hive cache first
    var box = await Hive.openBox('collections');
    final cached = box.get('allCollections');
    if (cached != null && cached is List) {
      _collections = cached
          .map((e) => Collection.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    // Always fetch latest from Firestore
    final collections = await _collectionService.getAllCollections();
    setState(() {
      _collections = collections;
    });
    // Cache to Hive
    await box.put(
      'allCollections',
      collections.map((c) => c.toJson()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter collections by type
    final proCollections = _collections.where((c) => c.type == 'pro').toList();
    final freeCollections = _collections.where((c) => c.type == 'free').toList();
    final premiumCollections = _collections.where((c) => c.type == 'premium').toList();
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: RefreshIndicator(
        onRefresh: _fetchCollections,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Only show sections with non-empty collections
              if (_collections.isNotEmpty)
                _buildCollectionSection('All Collections', _collections),
              
              if (proCollections.isNotEmpty)
                _buildCollectionSection('Pro Collections', proCollections),
              
              if (freeCollections.isNotEmpty)
                _buildCollectionSection('Free Collections', freeCollections),
              
              if (premiumCollections.isNotEmpty)
                _buildCollectionSection('Premium Collections', premiumCollections),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionSection(String title, List<Collection> collections) {
    // Double-check that collections is not empty before building the section
    if (collections.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Determine what type this section represents
    String? collectionType;
    if (title.toLowerCase().contains('pro')) {
      collectionType = 'pro';
    } else if (title.toLowerCase().contains('free')) {
      collectionType = 'free';
    } else if (title.toLowerCase().contains('premium')) {
      collectionType = 'premium';
    } else if (!title.toLowerCase().contains('all')) {
      // For custom categories, use the title directly
      collectionType = title.toLowerCase();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        title.toLowerCase().contains('free')
                            ? Colors.amber
                            : title.toLowerCase().contains('pro')
                            ? Colors.cyanAccent
                            : title.toLowerCase().contains('premium')
                            ? Colors.purpleAccent
                            : Colors.orangeAccent,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CollectionListPage(
                          title: title,
                          type: collectionType,
                          initialCollections: _collections,
                          // Don't pass bottom nav parameters from here
                          // The bottom nav should only be shown on main app screens
                          // showBottomNav: true,
                          // currentNavIndex: 1,
                        ),
                      ),
                    );
                  },
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: collections.length,
              separatorBuilder: (context, i) => const SizedBox(width: 16),
              itemBuilder: (context, i) {
                final collection = collections[i];
                return GestureDetector(
                  onTap: () async {
                    final wallpapers = await _collectionService
                        .getWallpapersForCollection(collection);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CollectionDetailPage(
                              title: collection.name,
                              author: collection.createdBy,
                              wallpapers:
                                  wallpapers.map((w) => w.toJson()).toList(),
                            ),
                      ),
                    );
                  },
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.10),
                        width: 1.0,
                      ),
                      color: Colors.white.withOpacity(0.08), // glass effect base
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          if ((collection.coverImage != null && collection.coverImage!.isNotEmpty) || collection.coverImage.isNotEmpty)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: CachedNetworkImage(
                                  imageUrl: (collection.coverImage != null && collection.coverImage!.isNotEmpty)
                                      ? collection.coverImage!
                                      : collection.coverImage,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  placeholder: (context, url) => Container(color: Colors.grey[700]),
                                  errorWidget: (context, url, error) => Container(color: Colors.grey[900]),
                                ),
                              ),
                            ),
                          // Gradient overlay for text readability
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.55),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  collection.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 26,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  collection.description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.1,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 6,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (collection.type == 'premium')
                            Positioned(
                              right: 18,
                              top: 18,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24, width: 1),
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
