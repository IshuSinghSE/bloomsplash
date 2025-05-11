import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/firebase/firebase_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallpaper_model.dart';
import 'edit_wallpaper_page.dart';
import '../widgets/wallpaper_utils.dart'; // Import the utility file
import '../utils/image_cache_utils.dart'; // Import the utility file

class MyUploadsPage extends StatefulWidget {
  const MyUploadsPage({super.key});

  @override
  State<MyUploadsPage> createState() => _MyUploadsPageState();
}

class _MyUploadsPageState extends State<MyUploadsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  // Cache manager instance
  List<Wallpaper> _uploadedWallpapers = [];
  List<Wallpaper> _filteredWallpapers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _selectedFilter = 'All'; // Default filter
  DocumentSnapshot? _lastDocument; // Track the last document for pagination
  final int _wallpapersPerPage = 10; // Number of wallpapers to load per page
  late Box _wallpapersBox; // Hive box for storing wallpapers locally

  @override
  void initState() {
    super.initState();
    _initializeHive();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initializeHive() async {
    _wallpapersBox = await Hive.openBox('uploadedWallpapers');
    _loadWallpapersFromLocalStorage();
  }

  void _loadWallpapersFromLocalStorage() {
    final storedWallpapers = _wallpapersBox.get('wallpapers', defaultValue: []);
    if (storedWallpapers.isNotEmpty) {
      setState(() {
        _uploadedWallpapers =
            (storedWallpapers as List)
                .map(
                  (wallpaperJson) =>
                      Wallpaper.fromJson(json.decode(wallpaperJson)),
                )
                .toList();
        _applyFilter();
        _isLoading = false;
      });
    } else {
      _fetchUploadedWallpapers();
    }
  }

  Future<void> _saveWallpapersToLocalStorage() async {
    final wallpapersJson =
        _uploadedWallpapers
            .map((wallpaper) => json.encode(wallpaper.toJson()))
            .toList();
    await _wallpapersBox.put('wallpapers', wallpapersJson);
  }

  Future<void> _fetchUploadedWallpapers({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        setState(() {
          _isLoading = true;
          _uploadedWallpapers.clear(); // Clear the list on refresh
          _lastDocument = null; // Reset pagination
        });
      } else {
        setState(() {
          _isLoadingMore = true;
        });
      }

      final result = await _firestoreService.getPaginatedWallpapers(
        limit: _wallpapersPerPage,
        lastDocument: isRefresh ? null : _lastDocument,
      );

      setState(() {
        _lastDocument = result['lastDocument'];
        final newWallpapers = result['wallpapers'];
        if (isRefresh) {
          _uploadedWallpapers = newWallpapers; // Replace the list on refresh
        } else {
          _uploadedWallpapers.addAll(newWallpapers); // Append new wallpapers
        }
        _applyFilter();
        _isLoading = false;
        _isLoadingMore = false;
      });

      // Save wallpapers to local storage
      await _saveWallpapersToLocalStorage();
      await _cacheImages(); // Cache images locally
    } catch (e) {
      debugPrint('Error fetching uploaded wallpapers: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _cacheImages() async {
    final imageUrls =
        _uploadedWallpapers
            .map((wallpaper) => wallpaper.thumbnailUrl)
            .where((url) => url.startsWith('http'))
            .toList();
    await cacheImages(imageUrls); // Use the utility function
  }

  Future<void> _refreshUploadedWallpapers() async {
    await _fetchUploadedWallpapers(isRefresh: true);
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredWallpapers = _uploadedWallpapers;
      } else {
        _filteredWallpapers =
            _uploadedWallpapers
                .where(
                  (wallpaper) =>
                      wallpaper.status.toLowerCase() ==
                      _selectedFilter.toLowerCase(),
                )
                .toList();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _lastDocument != null) {
      _fetchUploadedWallpapers();
    }
  }

  Future<void> _deleteWallpaper(String id) async {
    try {
      await _firestoreService.deleteImageDetailsFromFirestore(id);
      setState(() {
        _uploadedWallpapers.removeWhere((wallpaper) => wallpaper.id == id);
        _applyFilter();
      });
      await _saveWallpapersToLocalStorage(); // Update local storage
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
    await downloadWallpaper(context, url); // Use the existing function
  }

  void _editWallpaper(Wallpaper wallpaper) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditWallpaperPage(wallpaper: wallpaper),
      ),
    ).then((_) {
      _applyFilter(); // Reapply filter after returning
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Uploads'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
                _applyFilter();
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
            child: Padding(
              padding: const EdgeInsets.only(right: 32.0),
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
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUploadedWallpapers, // Ensure this calls the refresh method
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredWallpapers.isEmpty
                ? const Center(child: Text('No wallpapers found.'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredWallpapers.length +
                        (_isLoadingMore ? 1 : 0), // Add loading indicator
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
                            padding: const EdgeInsets.fromLTRB(12.0, 0, 0.0, 0),
                            child: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editWallpaper(wallpaper);
                                } else if (value == 'delete') {
                                  _deleteWallpaper(wallpaper.id);
                                } else if (value == 'download') {
                                  _downloadImage(wallpaper.previewUrl);
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
