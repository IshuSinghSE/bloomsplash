import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../services/firebase/firebase_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/wallpaper_model.dart';
import '../../edit_wallpaper/screens/edit_wallpaper_page.dart';
import '../../wallpaper_details/widgets/wallpaper_utils.dart';
import '../../../utils/image_cache_utils.dart';

class MyUploadsPage extends StatefulWidget {
  const MyUploadsPage({super.key});

  @override
  State<MyUploadsPage> createState() => _MyUploadsPageState();
}

class _MyUploadsPageState extends State<MyUploadsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  List<Wallpaper> _uploadedWallpapers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  String _selectedFilter = 'All';
  late Box _wallpapersBox;

  static const int _lazyLoadBatchSize = 15; // Load 15 at a time for lazy loading

  @override
  void initState() {
    super.initState();
    _initHiveAndLoad();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initHiveAndLoad() async {
    _wallpapersBox = await Hive.openBox('uploadedWallpapers');
    _loadWallpapersFromLocal();
    // If no cache, fetch from Firestore
    if (_uploadedWallpapers.isEmpty) {
      await _fetchWallpapers(isRefresh: true, forceFetch: true);
    }
  }

  void _loadWallpapersFromLocal() {
    final storedWallpapers = _wallpapersBox.get('wallpapers', defaultValue: []);
    final cacheTimestamp = _wallpapersBox.get('cacheTimestamp', defaultValue: 0);
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Check if cache is expired (e.g., 7 days)
    if (currentTime - cacheTimestamp > 7 * 24 * 60 * 60 * 1000) {
      debugPrint('Cache expired. Fetching fresh data.');
      _fetchWallpapers(isRefresh: true, forceFetch: true);
      return;
    }

    if (storedWallpapers.isNotEmpty) {
      setState(() {
        _uploadedWallpapers = (storedWallpapers as List)
            .map((wallpaperJson) => Wallpaper.fromJson(json.decode(wallpaperJson)))
            .toList();
        _isLoading = false;
      });
      _cacheImages();
    }
  }

  Future<void> _saveWallpapersToLocal(List<Wallpaper> wallpapers) async {
    final wallpapersJson = wallpapers.map((w) => json.encode(w.toJson())).toList();
    await _wallpapersBox.put('wallpapers', wallpapersJson);
    await _wallpapersBox.put('cacheTimestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _fetchWallpapers({bool isRefresh = false, bool forceFetch = false}) async {
    if (!forceFetch && !isRefresh && !_hasMore) return;

    try {
      if (isRefresh) {
        setState(() {
          _isLoading = true;
          _uploadedWallpapers.clear();
          _lastDocument = null;
          _hasMore = true;
        });
      } else {
        setState(() {
          _isLoadingMore = true;
        });
      }

      final result = await _firestoreService.getPaginatedWallpapers(
        limit: _lazyLoadBatchSize,
        lastDocument: isRefresh ? null : _lastDocument,
      );

      setState(() {
        _lastDocument = result['lastDocument'];
        final newWallpapers = result['wallpapers'];
        if (isRefresh) {
          _uploadedWallpapers = newWallpapers;
        } else {
          _uploadedWallpapers.addAll(newWallpapers);
        }
        if (newWallpapers.length < _lazyLoadBatchSize) {
          _hasMore = false;
        }
        _isLoading = false;
        _isLoadingMore = false;
      });

      await _saveWallpapersToLocal(_uploadedWallpapers);
      await _cacheImages();
    } catch (e) {
      debugPrint('Error fetching uploaded wallpapers: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      // Retry mechanism
      Future.delayed(const Duration(seconds: 3), () {
        if (!_isLoading && !_isLoadingMore) {
          _fetchWallpapers(isRefresh: isRefresh, forceFetch: forceFetch);
        }
      });
    }
  }

  Future<void> _cacheImages() async {
    final imageUrls = _uploadedWallpapers
        .map((wallpaper) => wallpaper.thumbnailUrl)
        .where((url) => url.startsWith('http'))
        .toList();
    await cacheImages(imageUrls);
  }

  Future<void> _refreshWallpapers() async {
    await _fetchWallpapers(isRefresh: true, forceFetch: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _lastDocument != null &&
        _hasMore) {
      _fetchWallpapers(isRefresh: false, forceFetch: true);
    }
  }

  Future<void> _deleteWallpaper(String id) async {
    try {
      await _firestoreService.deleteImageDetailsFromFirestore(id);
      setState(() {
        _uploadedWallpapers.removeWhere((wallpaper) => wallpaper.id == id);
      });
      await _saveWallpapersToLocal(_uploadedWallpapers);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallpaper deleted successfully!')),
      );
    } catch (e) {
      debugPrint('Error deleting wallpaper: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete wallpaper!')),
      );
    }
  }

  Future<void> _downloadImage(String url) async {
    await downloadWallpaper(context, url);
  }

  void _editWallpaper(Wallpaper wallpaper) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditWallpaperPage(wallpaper: wallpaper),
      ),
    ).then((didUpdate) async {
      if (didUpdate == true) {
        await _refreshWallpapers();
      }
      // else do nothing, avoid unnecessary loading
    });
  }

  List<Wallpaper> get _filteredWallpapers {
    if (_selectedFilter == 'All') return _uploadedWallpapers;
    return _uploadedWallpapers
        .where((w) => w.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Uploads'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(
                _selectedFilter == 'Approved'
                    ? Icons.check_circle
                    : _selectedFilter == 'Rejected'
                    ? Icons.cancel
                    : _selectedFilter == 'Pending'
                    ? Icons.hourglass_top
                    : Icons.filter_list,
                color:
                    _selectedFilter == 'Approved'
                        ? Colors.green
                        : _selectedFilter == 'Rejected'
                        ? Colors.red
                        : _selectedFilter == 'Pending'
                        ? Colors.amber
                        : Colors.white,
              ),
            ),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'All', child: Text('All')),
                  const PopupMenuItem(
                    value: 'Approved',
                    child: Text('Approved'),
                  ),
                  const PopupMenuItem(value: 'Pending', child: Text('Pending')),
                  const PopupMenuItem(
                    value: 'Rejected',
                    child: Text('Rejected'),
                  ),
                ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWallpapers,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWallpapers.isEmpty
                ? const Center(child: Text('No wallpapers found.'))
                : ListView.builder(
                  controller: _scrollController,
                  itemCount:
                      _filteredWallpapers.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _filteredWallpapers.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final wallpaper = _filteredWallpapers[index];
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () => _editWallpaper(wallpaper),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              wallpaper.thumbnailUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          wallpaper.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle: Text(
                          'Category: ${wallpaper.category}',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        trailing: Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editWallpaper(wallpaper);
                              } else if (value == 'delete') {
                                _deleteWallpaper(wallpaper.id);
                              } else if (value == 'download') {
                                _downloadImage(wallpaper.imageUrl);
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'download',
                                    child: Text('Download'),
                                  ),
                                ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}