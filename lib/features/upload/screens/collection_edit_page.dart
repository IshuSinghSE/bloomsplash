import 'dart:io';
import 'package:bloomsplash/core/constant/config.dart';
import 'package:bloomsplash/core/utils/utils.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../models/collection_model.dart';
import '../../../../../models/wallpaper_model.dart';
import '../../../app/services/firebase/collection_db.dart';
import '../../../app/services/firebase/firebase_storage.dart' as custom_storage;
import '../../../app/services/firebase/wallpaper_db.dart';

class CollectionEditPage extends StatefulWidget {
  final Collection collection;
  final List<Wallpaper> wallpapers;
  const CollectionEditPage({
    super.key,
    required this.collection,
    required this.wallpapers,
  });

  @override
  State<CollectionEditPage> createState() => _CollectionEditPageState();
}

class _CollectionEditPageState extends State<CollectionEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _tagsController;
  late TextEditingController _typeController;
  String? _coverImageUrl;
  bool _isUploadingCover = false;
  // XFile? _pickedCoverImage;
  List<Wallpaper> _wallpapers = [];
  bool _isUploadingWallpaper = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _descController = TextEditingController(
      text: widget.collection.description,
    );
    _tagsController = TextEditingController(
      text: widget.collection.tags.join(', '),
    );
    _typeController = TextEditingController(text: widget.collection.type);
    _coverImageUrl = widget.collection.coverImage;
    _wallpapers = List.from(widget.wallpapers);
  }

  Future<void> _pickAndUploadCoverImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: true,
    );
    if (image == null) return;
    setState(() {
      _isUploadingCover = true;
    });
    final file = File(image.path);
    final result = await custom_storage.uploadFileToFirebase(file);
    if (result != null && result['thumbnailUrl'] != null) {
      setState(() {
        _coverImageUrl = result['thumbnailUrl'];
        _isUploadingCover = false;
      });
    } else {
      setState(() {
        _isUploadingCover = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload cover image.')),
      );
    }
  }

  Future<void> _pickAndUploadWallpaper() async {
    // Get userData from Hive preferences
    var preferencesBox = Hive.box('preferences');
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
      _isUploadingWallpaper = true;
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
        // Compute hash (if you have a hash utility, otherwise leave as empty string)
        // import '../../../core/utils/hash_utils.dart' and use: hash = await computeImageHash(file);
        // If not available, leave as empty string
      } catch (e) {
        debugPrint('Hash computation failed: $e');
      }
      try {
        // Extract dominant colors from thumbnail
        // Use the picked image file directly as the thumbnail file
        File thumbFile = file;
        colors = await extractDominantColors(thumbFile);
      } catch (e) {
        debugPrint('Color extraction failed: $e');
      }
      // Set author and authorImage (if you have userData, otherwise fallback)

      // If you want to fetch userData from preferences, you can do so here
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
        collectionId: widget.collection.id,
      );
      await FirestoreService().addImageDetailsToFirestore(newWallpaper);
      await CollectionService().addWallpaperToCollection(
        widget.collection.id,
        newWallpaper.id,
      );
      setState(() {
        _wallpapers.add(newWallpaper);
        _isUploadingWallpaper = false;
      });
    } else {
      setState(() {
        _isUploadingWallpaper = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload wallpaper.')),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.collection.copyWith(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      coverImage: _coverImageUrl ?? '',
      tags:
          _tagsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
      type: _typeController.text.trim(),
      wallpaperIds: _wallpapers.map((w) => w.id).toList(),
    );
    await CollectionService().updateCollection(updated);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Collection updated!')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Collection'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 160,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[300],
                        image:
                            _coverImageUrl != null && _coverImageUrl!.isNotEmpty
                                ? DecorationImage(
                                  image: NetworkImage(_coverImageUrl!),
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child:
                          _coverImageUrl == null || _coverImageUrl!.isEmpty
                              ? const Center(
                                child: Icon(Icons.collections, size: 48),
                              )
                              : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed:
                            _isUploadingCover ? null : _pickAndUploadCoverImage,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isUploadingCover)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                ),
              ),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Wallpapers in Collection',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        _isUploadingWallpaper ? null : _pickAndUploadWallpaper,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Wallpaper'),
                  ),
                ],
              ),
              if (_isUploadingWallpaper)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(),
                ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _wallpapers.length,
                itemBuilder: (context, i) {
                  final w = _wallpapers[i];
                  return ListTile(
                    leading:
                        w.thumbnailUrl.isNotEmpty
                            ? Image.network(
                              w.thumbnailUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            )
                            : const Icon(Icons.image),
                    title: Text(w.name),
                    subtitle: Text(w.category),
                  );
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
