import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/firebase/firebase_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallpaper_model.dart';
import 'edit_wallpaper_page.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../widgets/wallpaper_utils.dart'; // Import the utility file

class MyUploadsPage extends StatefulWidget {
  const MyUploadsPage({super.key});

  @override
  State<MyUploadsPage> createState() => _MyUploadsPageState();
}

class _MyUploadsPageState extends State<MyUploadsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
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
        _uploadedWallpapers = (storedWallpapers as List)
            .map((wallpaperJson) => Wallpaper.fromJson(json.decode(wallpaperJson)))
            .toList();
        _applyFilter();
        _isLoading = false;
      });
    } else {
      _fetchUploadedWallpapers();
    }
  }

  Future<void> _saveWallpapersToLocalStorage() async {
    final wallpapersJson = _uploadedWallpapers
        .map((wallpaper) => json.encode(wallpaper.toJson()))
        .toList();
    await _wallpapersBox.put('wallpapers', wallpapersJson);
  }

  Future<void> _fetchUploadedWallpapers({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        setState(() {
          _isLoadingMore = true;
        });
      } else {
        setState(() {
          _isLoading = true;
        });
      }

      final result = await _firestoreService.getPaginatedWallpapers(
        limit: _wallpapersPerPage,
        lastDocument: _lastDocument,
      );

      setState(() {
        if (isLoadMore) {
          _uploadedWallpapers.addAll(result['wallpapers']);
        } else {
          _uploadedWallpapers = result['wallpapers'];
        }
        _lastDocument = result['lastDocument'];
        _applyFilter();
        _isLoading = false;
        _isLoadingMore = false;
      });

      // Save wallpapers to local storage
      await _saveWallpapersToLocalStorage();
    } catch (e) {
      debugPrint('Error fetching uploaded wallpapers: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredWallpapers = _uploadedWallpapers;
      } else {
        _filteredWallpapers = _uploadedWallpapers
            .where((wallpaper) =>
                wallpaper.status.toLowerCase() ==
                _selectedFilter.toLowerCase())
            .toList();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _lastDocument != null) {
      _fetchUploadedWallpapers(isLoadMore: true);
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

  Future<void> _replaceImage(
      String oldUrl, String newFilePath, String firestoreField, String id) async {
    try {
      // Delete the old image
      final oldRef = FirebaseStorage.instance.refFromURL(oldUrl);
      await oldRef.delete();

      // Upload the new image
      final newFile = File(newFilePath);
      final newRef = FirebaseStorage.instance
          .ref()
          .child('wallpapers/$firestoreField/${DateTime.now().millisecondsSinceEpoch}');
      await newRef.putFile(newFile);
      final newUrl = await newRef.getDownloadURL();

      // Update Firestore
      await _firestoreService.updateImageDetailsInFirestore(
        id: id,
        name: 'Updated Name', // Replace with actual name
        imageUrl: firestoreField == 'original' ? newUrl : null,
        thumbnailUrl: firestoreField == 'thumbnail' ? newUrl : null,
        previewUrl: firestoreField == 'preview' ? newUrl : null,
        downloads: 0, // Replace with actual downloads
        size: '0', // Replace with actual size
        resolution: '0x0', // Replace with actual resolution
        category: 'Updated Category', // Replace with actual category
        author: 'Updated Author', // Replace with actual author
        authorImage: 'Updated Author Image', // Replace with actual author image
        description: 'Updated Description', // Replace with actual description
        tags: [], // Replace with actual tags
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image replaced successfully!')),
      );
    } catch (e) {
      debugPrint('Error replacing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to replace image!')),
      );
    }
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
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Approved', child: Text('Approved')),
              const PopupMenuItem(value: 'Pending', child: Text('Pending')),
              const PopupMenuItem(value: 'Rejected', child: Text('Rejected')),
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
              color: _selectedFilter == 'Approved'
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
      body: _isLoading
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
                            itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            const PopupMenuItem(value: 'download', child: Text('Download')),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
