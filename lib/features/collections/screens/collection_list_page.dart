import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../models/collection_model.dart';
import '../../../app/services/firebase/collection_db.dart';
import '../../../features/shared/widgets/custom_bottom_nav_bar.dart';
import 'collection_detail_page.dart';
import '../../../../main.dart';

class CollectionListPage extends StatefulWidget {
  final String title;
  final String? type; // Optional type filter (null means 'All Collections')
  final List<Collection> initialCollections;
  final bool showBottomNav; // Control whether to show bottom nav
  final int currentNavIndex; // Current index for bottom nav

  const CollectionListPage({
    super.key,
    required this.title,
    this.type,
    required this.initialCollections,
    this.showBottomNav = true,
    this.currentNavIndex = 1, // Default to Collections tab
  });

  @override
  State<CollectionListPage> createState() => _CollectionListPageState();
}

class _CollectionListPageState extends State<CollectionListPage> {
  final CollectionService _collectionService = CollectionService();
  List<Collection> _collections = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCollections();
  }

  void _initializeCollections() {
    // Filter collections if a type is provided
    if (widget.type != null) {
      _collections = widget.initialCollections
          .where((c) => c.type == widget.type)
          .toList();
    } else {
      _collections = List.from(widget.initialCollections);
    }
  }

  Future<void> _refreshCollections() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch fresh collections from Firestore
      final allCollections = await _collectionService.getAllCollections();
      
      // Apply type filter if needed
      if (widget.type != null) {
        _collections = allCollections
            .where((c) => c.type == widget.type)
            .toList();
      } else {
        _collections = allCollections;
      }
    } catch (e) {
      debugPrint('Error refreshing collections: $e');
      // Show error message if needed
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onNavItemTapped(int index) {
    if (index == widget.currentNavIndex) {
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: widget.title.toLowerCase().contains('free')
              ? Colors.amber
              : widget.title.toLowerCase().contains('pro')
                  ? Colors.cyanAccent
                  : widget.title.toLowerCase().contains('premium')
                      ? Colors.purpleAccent
                      : Colors.orangeAccent,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCollections,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _collections.isEmpty
                ? const Center(child: Text('No collections found', style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                    // Add padding at the bottom for the nav bar if it's visible
                    padding: EdgeInsets.fromLTRB(16, 16, 16, widget.showBottomNav ? 84 : 16),
                    itemCount: _collections.length,
                    itemBuilder: (context, index) {
                      final collection = _collections[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: GestureDetector(
                          onTap: () async {
                            final wallpapers = await _collectionService
                                .getWallpapersForCollection(collection);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CollectionDetailPage(
                                  title: collection.name,
                                  author: collection.createdBy,
                                  wallpapers: wallpapers.map((w) => w.toJson()).toList(),
                                  // Remove these parameters to avoid bottom nav in detail page
                                  // showBottomNav: widget.showBottomNav,
                                  // currentNavIndex: widget.currentNavIndex,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                              image: collection.coverImage.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(collection.coverImage),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: Colors.grey[800],
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Overlay for better text visibility
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Collection info
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        collection.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '${collection.wallpaperIds.length} wallpapers',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          if (collection.tags.isNotEmpty)
                                            Text(
                                              collection.tags.first,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.6),
                                                fontSize: 14,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Premium indicator
                                if (collection.type == 'premium')
                                  Positioned(
                                    right: 12,
                                    top: 12,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                        vertical: 6.0,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.lock,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'PREMIUM',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
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
      // Add the bottom navigation bar if requested
      bottomNavigationBar: widget.showBottomNav
          ? CustomBottomNavBar(
              selectedIndex: widget.currentNavIndex,
              onItemTapped: _onNavItemTapped,
            )
          : null,
    );
  }
}
