import 'package:flutter/material.dart';
import '../../../models/wallpaper_model.dart';
import '../../../services/firebase/firebase_firestore_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../wallpaper_details/widgets/wallpaper_utils.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class EditWallpaperPage extends StatefulWidget {
  final Wallpaper wallpaper;

  const EditWallpaperPage({super.key, required this.wallpaper});

  @override
  State<EditWallpaperPage> createState() => _EditWallpaperPageState();
}

class _EditWallpaperPageState extends State<EditWallpaperPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  late TextEditingController _colorsController;
  late TextEditingController _orientationController;
  late TextEditingController _resolutionController;
  late TextEditingController _licenseController;
  late TextEditingController _statusController;

  String _selectedTab = 'Thumbnail'; // Default to "Thumbnail"
  late CacheManager _cacheManager; // Custom cache manager instance
  final Map<String, File?> _cachedImages = {}; // Cache for images

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wallpaper.name);
    _categoryController = TextEditingController(text: widget.wallpaper.category);
    _descriptionController = TextEditingController(text: widget.wallpaper.description);
    _tagsController = TextEditingController(text: widget.wallpaper.tags.join(', '));
    _colorsController = TextEditingController(text: widget.wallpaper.colors.join(', '));
    _orientationController = TextEditingController(text: widget.wallpaper.orientation);
    _resolutionController = TextEditingController(text: widget.wallpaper.resolution);
    _licenseController = TextEditingController(text: widget.wallpaper.license);
    _statusController = TextEditingController(text: widget.wallpaper.status);

    _cacheManager = CacheManager(
      Config(
        'customCacheKey', // Unique cache key
        stalePeriod: const Duration(days: 7), // Cache expiration duration
        maxNrOfCacheObjects: 50, // Maximum number of cached objects
      ),
    );

    _loadThumbnail(); // Only load thumbnail initially
  }

  Future<void> _loadThumbnail() async {
    try {
      final thumbnailFile = await _cacheManager.getSingleFile(widget.wallpaper.thumbnailUrl);
      setState(() {
        _cachedImages['Thumbnail'] = thumbnailFile;
      });
    } catch (e) {
      debugPrint('Error caching thumbnail: $e');
    }
  }

  Future<void> _loadOriginal() async {
    if (_cachedImages['Original'] != null) return;
    try {
      final originalFile = await _cacheManager.getSingleFile(widget.wallpaper.imageUrl);
      setState(() {
        _cachedImages['Original'] = originalFile;
      });
    } catch (e) {
      debugPrint('Error caching original: $e');
    }
  }

  void _onTabSelected(String tab) {
    setState(() {
      _selectedTab = tab;
    });
    if (tab == 'Original') {
      _loadOriginal();
    }
    // Thumbnail is loaded in initState
  }

  File? _getCachedImage(String tab) {
    return _cachedImages[tab];
  }

  Future<void> _downloadImage() async {
    final url = _selectedTab == 'Thumbnail'
        ? widget.wallpaper.thumbnailUrl
        : widget.wallpaper.imageUrl;

    final suffix = _selectedTab == 'Thumbnail'
        ? '_thumbnail'
        : ''; // No suffix for original

    final fileName = '${widget.wallpaper.name.replaceAll(' ', '_')}$suffix.jpg';

    await downloadWallpaper(context, url, fileName: fileName);
  }

  Future<void> _replaceImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      final newFile = File(pickedFile.path);
      final field = _selectedTab.toLowerCase(); // thumbnail or original
      final oldUrl = _selectedTab == 'Thumbnail'
          ? widget.wallpaper.thumbnailUrl
          : widget.wallpaper.imageUrl;

      final oldRef = FirebaseStorage.instance.refFromURL(oldUrl);
      await oldRef.delete();

      final newRef = FirebaseStorage.instance
          .ref()
          .child('wallpapers/$field/${DateTime.now().millisecondsSinceEpoch}');
      await newRef.putFile(newFile);
      final newUrl = await newRef.getDownloadURL();

      await _firestoreService.updateImageDetailsInFirestore(
        id: widget.wallpaper.id,
        name: widget.wallpaper.name,
        imageUrl: field == 'original' ? newUrl : widget.wallpaper.imageUrl,
        thumbnailUrl: field == 'thumbnail' ? newUrl : widget.wallpaper.thumbnailUrl,
        downloads: widget.wallpaper.downloads,
        size: widget.wallpaper.size.toString(),
        resolution: widget.wallpaper.resolution,
        category: widget.wallpaper.category,
        author: widget.wallpaper.author,
        authorImage: widget.wallpaper.authorImage,
        description: widget.wallpaper.description,
        tags: widget.wallpaper.tags,
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

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _firestoreService.updateImageDetailsInFirestore(
          id: widget.wallpaper.id,
          name: _nameController.text,
          imageUrl: widget.wallpaper.imageUrl,
          thumbnailUrl: widget.wallpaper.thumbnailUrl,
          downloads: widget.wallpaper.downloads,
          size: widget.wallpaper.size.toString(),
          resolution: _resolutionController.text,
          category: _categoryController.text,
          author: widget.wallpaper.author,
          authorImage: widget.wallpaper.authorImage,
          description: _descriptionController.text,
          tags: _tagsController.text.split(',').map((tag) => tag.trim()).toList(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper updated successfully!')),
        );
        Navigator.pop(context, true); // Pass true to indicate update
      } catch (e) {
        debugPrint('Error updating wallpaper: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update wallpaper!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cachedImage = _getCachedImage(_selectedTab);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Wallpaper'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tab Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['Thumbnail', 'Original'].map((tab) {
                return GestureDetector(
                  onTap: () => _onTabSelected(tab),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      tab,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedTab == tab ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Image Placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[300],
                image: cachedImage != null
                    ? DecorationImage(
                        image: FileImage(cachedImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: cachedImage == null
                  ? const Center(child: CircularProgressIndicator())
                  : null,
            ),
            const SizedBox(height: 16),

            // Download and Replace Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _downloadImage,
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _replaceImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Replace'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Editable Fields
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
                  ),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: (value) => value!.isEmpty ? 'Category cannot be empty' : null,
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(labelText: 'Tags (Comma-separated)'),
                  ),
                  TextFormField(
                    controller: _colorsController,
                    decoration: const InputDecoration(labelText: 'Colors (Comma-separated)'),
                  ),
                  TextFormField(
                    controller: _orientationController,
                    decoration: const InputDecoration(labelText: 'Orientation'),
                  ),
                  TextFormField(
                    controller: _resolutionController,
                    decoration: const InputDecoration(labelText: 'Resolution'),
                  ),
                  TextFormField(
                    controller: _licenseController,
                    decoration: const InputDecoration(labelText: 'License'),
                  ),
                  TextFormField(
                    controller: _statusController,
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}