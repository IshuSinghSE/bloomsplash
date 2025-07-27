import 'dart:convert';
import 'dart:io';
import 'package:bloomsplash/core/constant/config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../app/services/firebase/wallpaper_db.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/wallpaper_model.dart';
import '../../../models/collection_model.dart';
import 'edit_wallpaper_page.dart';
import '../../../core/utils/image_cache_utils.dart';
import '../../../app/services/firebase/collection_db.dart';
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
  String _formatDateTime(String isoString) {
    try {
      final date = DateTime.tryParse(isoString);
      if (date == null) return '';
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
  String _selectedStatus = 'approved';

  Icon _statusIcon(String status, {double size = 28}) {
    switch (status) {
      case 'approved':
        return Icon(Icons.check_circle, color: Colors.green, size: size);
      case 'pending':
        return Icon(Icons.hourglass_top, color: Colors.orange, size: size);
      case 'rejected':
        return Icon(Icons.cancel, color: Colors.red, size: size);
      default:
        return Icon(Icons.help_outline, color: Colors.grey, size: size);
    }
  }
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  List<Wallpaper> _uploadedWallpapers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  // final String _selectedFilter = 'All';
  late Box _wallpapersBox;

  // Collections tab state
  late TabController _tabController;
  List<Collection> _collections = [];
  bool _isLoadingCollections = true;

  static const int _lazyLoadBatchSize = 10;

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
    final cacheTimestamp = _wallpapersBox.get(
      'cacheTimestamp',
      defaultValue: 0,
    );
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Check if cache is expired (e.g., 7 days)
    if (currentTime - cacheTimestamp > 7 * 24 * 60 * 60 * 1000) {
      debugPrint('Cache expired. Fetching fresh data.');
      _fetchWallpapers(isRefresh: true, forceFetch: true);
      return;
    }

    if (storedWallpapers.isNotEmpty) {
      setState(() {
        _uploadedWallpapers =
            (storedWallpapers as List)
                .map(
                  (wallpaperJson) =>
                      Wallpaper.fromJson(json.decode(wallpaperJson)),
                )
                .where((w) => w.status == _selectedStatus)
                .toList();
        _isLoading = false;
      });
      _cacheImages();
    }
  }

  Future<void> _saveWallpapersToLocal(List<Wallpaper> wallpapers) async {
    final wallpapersJson =
        wallpapers.map((w) => json.encode(w.toJson())).toList();
    await _wallpapersBox.put('wallpapers', wallpapersJson);
    await _wallpapersBox.put(
      'cacheTimestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _fetchWallpapers({
    bool isRefresh = false,
    bool forceFetch = false,
  }) async {
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
        status: _selectedStatus,
      );

      setState(() {
        _lastDocument = result['lastDocument'];
        final newWallpapers = result['wallpapers'];
        if (isRefresh) {
          _uploadedWallpapers = newWallpapers;
        } else {
          _uploadedWallpapers.addAll(newWallpapers);
        }
        if (newWallpapers.isEmpty || newWallpapers.length < _lazyLoadBatchSize) {
          _hasMore = false;
        }
      });

      await _saveWallpapersToLocal(_uploadedWallpapers);
      await _cacheImages();
    } catch (e) {
      debugPrint('Error fetching uploaded wallpapers: $e');
    } finally {
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
      _collections =
          List<Map<String, dynamic>>.from(
            cached,
          ).map((e) => Collection.fromJson(e)).toList();
    }
    final collections = await CollectionService().getCollectionsPaginated(limit: 10);
    setState(() {
      _collections = collections;
      _isLoadingCollections = false;
    });
    await box.put(
      'allCollections',
      collections.map((c) => c.toJson()).toList(),
    );
  }

  Future<void> _showCollectionDialog({Collection? collection}) async {
    final nameController = TextEditingController(text: collection?.name ?? '');
    final descController = TextEditingController(
      text: collection?.description ?? '',
    );
    final coverController = TextEditingController(
      text: collection?.coverImage ?? '',
    );
    final tagsController = TextEditingController(
      text: collection?.tags.join(', ') ?? '',
    );
    final typeController = TextEditingController(text: collection?.type ?? '');
    final formKey = GlobalKey<FormState>();
    // XFile? pickedImage;
    String? uploadedImageUrl;
    bool isUploading = false;
    double uploadProgress = 0;
    String? selectedWallpaperId;
    // Only wallpapers in this collection, or all if new
    List<Wallpaper> availableWallpapers =
        collection?.wallpaperIds != null && collection!.wallpaperIds.isNotEmpty
            ? _uploadedWallpapers
                .where((w) => collection.wallpaperIds.contains(w.id))
                .toList()
            : _uploadedWallpapers;

    Future<void> pickAndUploadImage(String collectionId) async {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      setState(() {
        // pickedImage = image;
        isUploading = true;
        uploadProgress = 0;
        selectedWallpaperId = null; // Clear wallpaper selection if uploading
      });
      final file = File(image.path);

      // Simulate upload progress
      final uploadTask = custom_storage.uploadFileToFirebase(file);

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
        const Text(
          'Add a wallpaper to this collection (optional):',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Upload Wallpaper'),
          onPressed: isUploading
              ? null
              : () async {
                  // Get userData from Hive preferences
                  var preferencesBox = await Hive.openBox('preferences');
                  var userDataRaw = preferencesBox.get('userData', defaultValue: {});
                  Map<String, dynamic> userData;
                  if (userDataRaw is Map<String, dynamic>) {
                    userData = userDataRaw;
                  } else if (userDataRaw is Map) {
                    userData = Map<String, dynamic>.from(
                      userDataRaw.map((key, value) => MapEntry(key.toString(), value)),
                    );
                  } else {
                    userData = {};
                  }
                  final isAdmin = userData['isAdmin'] ?? false;
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                    requestFullMetadata: true,
                  );
                  if (image == null) return;
                  setState(() {
                    isUploading = true;
                  });
                  final file = File(image.path);
                  final result = await custom_storage.uploadFileToFirebase(file);
                  if (result != null &&
                      result['originalUrl'] != null &&
                      result['thumbnailUrl'] != null) {
                    // Compute hash and extract colors, set author fields
                    final now = DateTime.now();
                    String hash = '';
                    List<String> colors = [];
                    try {
                      // If you have a hash utility, use it here
                      // hash = await computeImageHash(file);
                    } catch (e) {
                      debugPrint('Hash computation failed: $e');
                    }
                    try {
                      File thumbFile = file;
                      colors = await extractDominantColors(thumbFile);
                    } catch (e) {
                      debugPrint('Color extraction failed: $e');
                    }
                    final newWallpaper = Wallpaper(
                      id: now.millisecondsSinceEpoch.toString(),
                      name: 'untitled',
                      imageUrl: result['originalUrl'],
                      thumbnailUrl: result['thumbnailUrl'],
                      downloads: 0,
                      likes: 0,
                      size: result['originalSize'] ?? 0,
                      resolution: result['originalResolution']?.toString() ?? '',
                      orientation: 'portrait',
                      category: 'Uncategorized',
                      tags: [],
                      colors: colors,
                      author: isAdmin == true
                          ? 'bloomsplash'
                          : (userData['displayName'] ?? 'Unknown'),
                      authorImage: isAdmin == true
                          ? AppConfig.adminImagePath
                          : (userData['photoUrl'] ?? AppConfig.authorIconPath),
                      description: '',
                      isPremium: false,
                      isAIgenerated: false,
                      status: 'approved',
                      createdAt: now.toIso8601String(),
                      license: 'free-commercial',
                      hash: hash,
                      collectionId: collection?.id ?? '',
                    );
                    await FirestoreService().addImageDetailsToFirestore(newWallpaper);
                    if (collection != null) {
                      await CollectionService().addWallpaperToCollection(collection.id, newWallpaper.id);
                    }
                    availableWallpapers.add(newWallpaper);
                    setState(() {
                      isUploading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wallpaper uploaded!')),
                    );
                  } else {
                    setState(() {
                      isUploading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to upload wallpaper.'),
                      ),
                    );
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
              title: Text(
                collection == null ? 'Create Collection' : 'Edit Collection',
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator:
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: coverController,
                              decoration: const InputDecoration(
                                labelText: 'Cover Image URL',
                              ),
                              readOnly: true,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.upload_file),
                            tooltip: 'Upload Custom Cover Image',
                            onPressed:
                                isUploading
                                    ? null
                                    : () async {
                                      final id =
                                          collection?.id ??
                                          DateTime.now().millisecondsSinceEpoch
                                              .toString();
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
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image),
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
                              items:
                                  availableWallpapers
                                      .map(
                                        (w) => DropdownMenuItem(
                                          value: w.id,
                                          child: Row(
                                            children: [
                                              Image.network(
                                                w.thumbnailUrl,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(w.name),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedWallpaperId = val;
                                  // pickedImage = null;
                                  uploadedImageUrl = null;
                                  if (val != null) {
                                    final selected = availableWallpapers
                                        .firstWhere((w) => w.id == val);
                                    coverController.text =
                                        selected.thumbnailUrl;
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
                        decoration: const InputDecoration(
                          labelText: 'Tags (comma separated)',
                        ),
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
                    if (coverImageUrl.isEmpty &&
                        availableWallpapers.isNotEmpty) {
                      coverImageUrl = availableWallpapers.first.thumbnailUrl;
                    }
                    final newCollection = Collection(
                      id: collection?.id ?? generateUuid(),
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      coverImage: coverImageUrl,
                      createdBy: 'admin', // Replace with actual user
                      tags:
                          tagsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList(),
                      type: typeController.text.trim(),
                      wallpaperIds: collection?.wallpaperIds ?? [],
                      createdAt: collection?.createdAt is DateTime
                          ? collection!.createdAt
                          : (collection?.createdAt is Timestamp
                              ? (collection!.createdAt as Timestamp).toDate()
                              : DateTime.now()),
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

  // --- New Wallpaper Upload Dialog ---
  Future<void> _showWallpaperUploadDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final tagsController = TextEditingController();
    final categoryController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    // XFile? pickedImage;
    bool isUploading = false;
    String? uploadedOriginalUrl;
    String? uploadedThumbnailUrl;
    int? uploadedSize;
    String? uploadedResolution;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Upload New Wallpaper'),
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
                      TextFormField(
                        controller: tagsController,
                        decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
                      ),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Pick Image'),
                        onPressed: isUploading
                            ? null
                            : () async {
                                final picker = ImagePicker();
                                final image = await picker.pickImage(source: ImageSource.gallery);
                                if (image == null) return;
                                setState(() {
                                  // pickedImage = image;
                                  isUploading = true;
                                });
                                final file = File(image.path);
                                final result = await custom_storage.uploadFileToFirebase(file);
                                if (result != null && result['originalUrl'] != null && result['thumbnailUrl'] != null) {
                                  setState(() {
                                    uploadedOriginalUrl = result['originalUrl'];
                                    uploadedThumbnailUrl = result['thumbnailUrl'];
                                    uploadedSize = result['originalSize'];
                                    uploadedResolution = result['originalResolution']?.toString();
                                    isUploading = false;
                                  });
                                } else {
                                  setState(() {
                                    isUploading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to upload image.')),
                                  );
                                }
                              },
                      ),
                      if (isUploading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: LinearProgressIndicator(),
                        ),
                      if (uploadedThumbnailUrl != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Image.network(
                            uploadedThumbnailUrl!,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                          ),
                        ),
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
                    if (uploadedOriginalUrl == null || uploadedThumbnailUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please pick and upload an image.')),
                      );
                      return;
                    }
                    // Get userData from Hive preferences
                    var preferencesBox = await Hive.openBox('preferences');
                    var userDataRaw = preferencesBox.get('userData', defaultValue: {});
                    Map<String, dynamic> userData;
                    if (userDataRaw is Map<String, dynamic>) {
                      userData = userDataRaw;
                    } else if (userDataRaw is Map) {
                      userData = Map<String, dynamic>.from(
                        userDataRaw.map((key, value) => MapEntry(key.toString(), value)),
                      );
                    } else {
                      userData = {};
                    }
                    final isAdmin = userData['isAdmin'] ?? false;
                    final now = DateTime.now();
                    String hash = '';
                    List<String> colors = [];
                    try {
                      // If you have a hash utility, use it here
                      // import '../../core/utils/hash_utils.dart' as hash_utils;
                      // hash = await hash_utils.computeImageHash(File(uploadedThumbnailUrl!));
                    } catch (e) {
                      debugPrint('Hash computation failed: $e');
                    }
                    try {
                      File thumbFile = File(uploadedThumbnailUrl!);
                      colors = await extractDominantColors(thumbFile);
                    } catch (e) {
                      debugPrint('Color extraction failed: $e');
                    }
                    final newWallpaper = Wallpaper(
                      id: now.millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim().isNotEmpty ? nameController.text.trim() : 'untitled',
                      imageUrl: uploadedOriginalUrl!,
                      thumbnailUrl: uploadedThumbnailUrl!,
                      downloads: 0,
                      likes: 0,
                      size: uploadedSize ?? 0,
                      resolution: uploadedResolution ?? '',
                      orientation: 'portrait',
                      category: categoryController.text.trim().isNotEmpty ? categoryController.text.trim() : 'Uncategorized',
                      tags: tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                      colors: colors,
                      author: isAdmin == true ? 'bloomsplash' : (userData['displayName'] ?? 'Unknown'),
                      authorImage: isAdmin == true ? AppConfig.adminImagePath : (userData['photoUrl'] ?? AppConfig.authorIconPath),
                      description: descController.text.trim(),
                      isPremium: false,
                      isAIgenerated: false,
                      status: 'approved',
                      createdAt: now.toIso8601String(),
                      license: 'free-commercial',
                      hash: hash,
                      collectionId: null,
                    );
                    await FirestoreService().addImageDetailsToFirestore(newWallpaper);
                    setState(() {
                      _uploadedWallpapers.insert(0, newWallpaper);
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wallpaper uploaded!')),
                    );
                  },
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

// --- UI --- 
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Uploads'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: PopupMenuButton<String>(
                icon: _statusIcon(_selectedStatus, size: 28),
                onSelected: (val) {
                  setState(() {
                    _selectedStatus = val;
                    _fetchWallpapers(isRefresh: true, forceFetch: true);
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'approved',
                    child: Row(
                      children: [
                        _statusIcon('approved', size: 20),
                        const SizedBox(width: 8),
                        const Text('Approved'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'pending',
                    child: Row(
                      children: [
                        _statusIcon('pending', size: 20),
                        const SizedBox(width: 8),
                        const Text('Pending'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'rejected',
                    child: Row(
                      children: [
                        _statusIcon('rejected', size: 20),
                        const SizedBox(width: 8),
                        const Text('Rejected'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Wallpapers'), Tab(text: 'Collections')],
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ListTile(
                          leading: wallpaper.thumbnailUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: wallpaper.thumbnailUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 48),
                                )
                              : const Icon(Icons.image, size: 48),
                          title: Text(wallpaper.name),
                          subtitle: Text(_formatDateTime(wallpaper.createdAt)),
                          trailing: _statusIcon(wallpaper.status, size: 22),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        EditWallpaperPage(wallpaper: wallpaper),
                              ),
                            );
                          },
                        ),
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
                            leading:
                                collection.coverImage.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: collection.coverImage,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const SizedBox(
                                          width: 56,
                                          height: 56,
                                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        ),
                                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 56),
                                    )
                                    : const Icon(Icons.collections),
                            title: Text(collection.name),
                            subtitle: Text(collection.description),
                            onTap: () async {
                              final wallpapers = await CollectionService()
                                  .getWallpapersForCollection(collection.id);
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => CollectionEditPage(
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
                  ],
                ),
          ],
        ),
        floatingActionButton:
            _tabController.index == 1
                ? FloatingActionButton(
                    onPressed: () => _showCollectionDialog(),
                    tooltip: 'New Collection',
                    child: const Icon(Icons.add_to_photos_rounded),
                  )
                : _tabController.index == 0
                    ? FloatingActionButton(
                        onPressed: () => _showWallpaperUploadDialog(),
                        tooltip: 'New Wallpaper',
                        child: const Icon(Icons.add_a_photo),
                      )
                    : null,
      ),
    );
  }
}
