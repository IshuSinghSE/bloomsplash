import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../app/services/firebase/firebase_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/wallpaper_model.dart';
import '../../../models/collection_model.dart';
import '../temp/create_collection.dart';
import '../temp/create_wallpaper.dart';
import 'edit_wallpaper_page.dart';
import '../../../core/utils/image_cache_utils.dart';
import '../../../app/services/firebase/collection_service.dart';
import 'collection_edit_page.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/services/firebase/firebase_storage.dart' as custom_storage;
import '../../../core/utils/utils.dart';
class MyUploadsPage extends StatefulWidget {
  const MyUploadsPage({super.key});

  @override
  State<MyUploadsPage> createState() => _MyUploadsPageState();
}

class _MyUploadsPageState extends State<MyUploadsPage> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  List<Wallpaper> _uploadedWallpapers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  final String _selectedFilter = 'All';
  late Box _wallpapersBox;

  // Collections tab state
  late TabController _tabController;
  List<Collection> _collections = [];
  bool _isLoadingCollections = true;

  static const int _lazyLoadBatchSize = 15;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {}); // Rebuild to update FAB on tab change
    });
    _initHiveAndLoad();
    _fetchCollections();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
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

  // --- Collections CRUD ---
  Future<void> _fetchCollections() async {
    setState(() => _isLoadingCollections = true);
    var box = await Hive.openBox('collections');
    final cached = box.get('allCollections');
    if (cached != null && cached is List) {
      _collections = List<Map<String, dynamic>>.from(cached)
          .map((e) => Collection.fromJson(e))
          .toList();
    }
    final collections = await CollectionService().getAllCollections();
    setState(() {
      _collections = collections;
      _isLoadingCollections = false;
    });
    await box.put('allCollections', collections.map((c) => c.toJson()).toList());
  }

  Future<void> _showCollectionDialog({Collection? collection}) async {
    final nameController = TextEditingController(text: collection?.name ?? '');
    final descController = TextEditingController(text: collection?.description ?? '');
    final coverController = TextEditingController(text: collection?.coverImage ?? '');
    final tagsController = TextEditingController(text: collection?.tags.join(', ') ?? '');
    final typeController = TextEditingController(text: collection?.type ?? '');
    final formKey = GlobalKey<FormState>();
    XFile? pickedImage;
    String? uploadedImageUrl;
    bool isUploading = false;
    double uploadProgress = 0;
    String? selectedWallpaperId;
    // Only wallpapers in this collection, or all if new
    List<Wallpaper> availableWallpapers = collection?.wallpaperIds != null && collection!.wallpaperIds.isNotEmpty
      ? _uploadedWallpapers.where((w) => collection.wallpaperIds.contains(w.id)).toList()
      : _uploadedWallpapers;

    Future<void> pickAndUploadImage(String collectionId) async {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      setState(() {
        pickedImage = image;
        isUploading = true;
        uploadProgress = 0;
        selectedWallpaperId = null; // Clear wallpaper selection if uploading
      });
      final file = File(image.path);

      // Simulate upload progress
      final uploadTask = custom_storage.uploadFileToFirebaseWithProgress(file, (progress) {
        setState(() {
          uploadProgress = progress;
        });
      });

      final result = await uploadTask;
      if (result != null && result['thumbnailUrl'] != null) {
        setState(() {
          uploadedImageUrl = result['thumbnailUrl'];
          coverController.text = uploadedImageUrl!;
          isUploading = false;
        });
      } else {
        setState(() {
          isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload cover image.')),
        );
      }
    }

    // --- Add wallpaper upload section ---
    Widget uploadWallpaperSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Add a wallpaper to this collection (optional):', style: TextStyle(fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Upload Wallpaper'),
          onPressed: isUploading ? null : () async {
            final picker = ImagePicker();
            final image = await picker.pickImage(source: ImageSource.gallery);
            if (image == null) return;
            setState(() { isUploading = true; });
            final file = File(image.path);
            final result = await custom_storage.uploadFileToFirebase(file);
            if (result != null && result['originalUrl'] != null && result['thumbnailUrl'] != null) {
              final newWallpaper = Wallpaper(
                id: generateUuid(),
                name: 'New Wallpaper',
                imageUrl: result['originalUrl'],
                thumbnailUrl: result['thumbnailUrl'],
                downloads: 0,
                size: result['originalSize'] ?? 0,
                resolution: result['originalResolution']?.toString() ?? '',
                category: '',
                author: 'admin',
                authorImage: '',
                description: '',
                likes: 0,
                tags: [],
                colors: [],
                orientation: '',
                license: '',
                status: 'active',
                createdAt: DateTime.now().toIso8601String(),
                isPremium: false,
                isAIgenerated: false,
                hash: ''
              );
              await FirestoreService().addImageDetailsToFirestore(newWallpaper);
              availableWallpapers.add(newWallpaper);
              setState(() { isUploading = false; });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wallpaper uploaded!')));
            } else {
              setState(() { isUploading = false; });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload wallpaper.')));
            }
          },
        ),
      ],
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(collection == null ? 'Create Collection' : 'Edit Collection'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: coverController,
                              decoration: const InputDecoration(labelText: 'Cover Image URL'),
                              readOnly: true,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.upload_file),
                            tooltip: 'Upload Custom Cover Image',
                            onPressed: isUploading ? null : () async {
                              final id = collection?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
                              await pickAndUploadImage(id);
                            },
                          ),
                        ],
                      ),
                      if (isUploading)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: LinearProgressIndicator(value: uploadProgress),
                        ),
                      if (coverController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Image.network(
                            coverController.text,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                          ),
                        ),
                      if (availableWallpapers.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            const Text('Or select a wallpaper as cover image:'),
                            DropdownButton<String>(
                              value: selectedWallpaperId,
                              hint: const Text('Select wallpaper'),
                              isExpanded: true,
                              items: availableWallpapers.map((w) => DropdownMenuItem(
                                value: w.id,
                                child: Row(
                                  children: [
                                    Image.network(w.thumbnailUrl, width: 40, height: 40, fit: BoxFit.cover),
                                    const SizedBox(width: 8),
                                    Text(w.name),
                                  ],
                                ),
                              )).toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedWallpaperId = val;
                                  pickedImage = null;
                                  uploadedImageUrl = null;
                                  if (val != null) {
                                    final selected = availableWallpapers.firstWhere((w) => w.id == val);
                                    coverController.text = selected.thumbnailUrl;
                                  } else {
                                    coverController.text = '';
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      TextFormField(
                        controller: tagsController,
                        decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
                      ),
                      TextFormField(
                        controller: typeController,
                        decoration: const InputDecoration(labelText: 'Type'),
                      ),
                      // --- Add wallpaper upload section ---
                      uploadWallpaperSection,
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    String coverImageUrl = coverController.text.trim();
                    if (coverImageUrl.isEmpty && availableWallpapers.isNotEmpty) {
                      coverImageUrl = availableWallpapers.first.thumbnailUrl;
                    }
                    final newCollection = Collection(
                      id: collection?.id ?? generateUuid(),
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      coverImage: coverImageUrl,
                      createdBy: 'admin', // Replace with actual user
                      tags: tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                      type: typeController.text.trim(),
                      wallpaperIds: collection?.wallpaperIds ?? [],
                      createdAt: collection?.createdAt ?? Timestamp.now(),
                    );
                    if (collection == null) {
                      await CollectionService().createCollection(newCollection);
                    } else {
                      await CollectionService().updateCollection(newCollection);
                    }
                    Navigator.pop(context);
                    await _fetchCollections();
                  },
                  child: Text(collection == null ? 'Create' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Uploads'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'My Uploads'),
              Tab(text: 'Collections'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // --- My Uploads Tab ---
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshWallpapers,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _uploadedWallpapers.length,
                      itemBuilder: (context, i) {
                        final wallpaper = _uploadedWallpapers[i];
                        return ListTile(
                          leading: (wallpaper.thumbnailUrl.isNotEmpty)
                              ? Image.network(wallpaper.thumbnailUrl, width: 56, height: 56, fit: BoxFit.cover)
                              : const Icon(Icons.image),
                          title: Text(wallpaper.name),
                          subtitle: Text(wallpaper.category),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditWallpaperPage(wallpaper: wallpaper),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
            // --- Collections Tab ---
            _isLoadingCollections
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: _fetchCollections,
                        child: ListView.builder(
                          itemCount: _collections.length,
                          itemBuilder: (context, i) {
                            final collection = _collections[i];
                            return ListTile(
                              leading: collection.coverImage.isNotEmpty
                                  ? Image.network(collection.coverImage, width: 56, height: 56, fit: BoxFit.cover)
                                  : const Icon(Icons.collections),
                              title: Text(collection.name),
                              subtitle: Text(collection.description),
                              onTap: () async {
                                final wallpapers = await CollectionService().getWallpapersForCollection(collection);
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CollectionEditPage(
                                      collection: collection,
                                      wallpapers: wallpapers,
                                    ),
                                  ),
                                );
                                if (updated == true) await _fetchCollections();
                              },
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingActionButton.extended(
                              heroTag: 'create-wallpaper',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateWallpaperPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text('New Wallpaper'),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.extended(
                              heroTag: 'create-collection',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateCollectionPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.collections_sharp),
                              label: const Text('New Collection'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ],
        ),
        floatingActionButton: _tabController.index == 1
            ? FloatingActionButton(
                onPressed: () => _showCollectionDialog(),
                tooltip: 'New Collection',
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}