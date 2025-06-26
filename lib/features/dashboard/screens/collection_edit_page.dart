import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:bloomsplash/core/utils/utils.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../models/collection_model.dart';
import '../../../../../models/wallpaper_model.dart';
import '../../../app/services/firebase/collection_db.dart';
import '../../../app/services/firebase/firebase_storage.dart' as custom_storage;
import '../../../app/services/firebase/wallpaper_db.dart';
import '../screens/wallpaper_selection_page.dart';

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
  bool _isLoadingWallpapers = false;
  bool _isSaving = false;
  bool _isRemoving = false;
  
  // Variables to track changes
  bool _hasChanges = false;
  late String _originalName;
  late String _originalDesc;
  late String _originalTags;
  late String _originalType;
  late String? _originalCoverImageUrl;
  late List<String> _originalWallpaperIds;

  // Getter to check if any operation is in progress
  bool get _isProcessing => 
      _isUploadingCover || 
      _isUploadingWallpaper || 
      _isLoadingWallpapers || 
      _isSaving ||
      _isRemoving;

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
    
    // Store original values for change detection
    _originalName = widget.collection.name;
    _originalDesc = widget.collection.description;
    _originalTags = widget.collection.tags.join(', ');
    _originalType = widget.collection.type;
    _originalCoverImageUrl = widget.collection.coverImage;
    _originalWallpaperIds = widget.collection.wallpaperIds;
    
    // Add listeners to detect changes
    _nameController.addListener(_checkForChanges);
    _descController.addListener(_checkForChanges);
    _tagsController.addListener(_checkForChanges);
    _typeController.addListener(_checkForChanges);
  }
  
  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _descController.removeListener(_checkForChanges);
    _tagsController.removeListener(_checkForChanges);
    _typeController.removeListener(_checkForChanges);
    _nameController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    _typeController.dispose();
    super.dispose();
  }
  
  void _checkForChanges() {
    final currentWallpaperIds = _wallpapers.map((w) => w.id).toList();
    final hasWallpaperChanges = !listEquals(_originalWallpaperIds, currentWallpaperIds);
    
    final hasChanges = 
        _nameController.text.trim() != _originalName.trim() ||
        _descController.text.trim() != _originalDesc.trim() ||
        _tagsController.text.trim() != _originalTags.trim() ||
        _typeController.text.trim() != _originalType.trim() ||
        _coverImageUrl != _originalCoverImageUrl ||
        hasWallpaperChanges;
    
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _pickAndUploadCoverImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
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
      _checkForChanges();
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
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _isUploadingWallpaper = true;
    });
    final file = File(image.path);
    final result = await custom_storage.uploadFileToFirebase(file);
    if (result != null &&
        result['originalUrl'] != null &&
        result['thumbnailUrl'] != null) {
      // Create wallpaper in Firestore
      final newWallpaper = Wallpaper(
        id: generateUuid(),
        name: 'New Wallpaper',
        imageUrl: result['originalUrl'],
        thumbnailUrl: result['thumbnailUrl'],
        downloads: 0,
        size: result['originalSize'] ?? 0,
        resolution: result['originalResolution']?.toString() ?? '',
        category: '',
        author: widget.collection.createdBy,
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
        hash: '',
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
      _checkForChanges();
    } else {
      setState(() {
        _isUploadingWallpaper = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload wallpaper.')),
      );
    }
  }
  
  void _removeWallpaperFromCollection(Wallpaper wallpaper) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Wallpaper'),
        content: const Text('Are you sure you want to remove this wallpaper from the collection?'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isProcessing 
                ? null 
                : () async {
                    Navigator.pop(context);
                    setState(() {
                      _isRemoving = true;
                    });
                    
                    try {
                      await CollectionService().removeWallpaperFromCollection(
                        widget.collection.id,
                        wallpaper.id,
                      );
                      
                      if (mounted) {
                        setState(() {
                          _wallpapers.removeWhere((w) => w.id == wallpaper.id);
                          _isRemoving = false;
                        });
                        _checkForChanges();
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isRemoving = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error removing wallpaper: $e')),
                        );
                      }
                    }
                  },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _selectExistingWallpapers() async {
    if (_isProcessing) return;
    
    setState(() {
      _isLoadingWallpapers = true;
    });
    
    try {
      final firestoreService = FirestoreService();
      final List<Wallpaper> allWallpapers = await firestoreService.getAllWallpapers();
      
      // Filter out wallpapers that are already in the collection
      final currentWallpaperIds = _wallpapers.map((w) => w.id).toSet();
      final availableWallpapers = allWallpapers
          .where((w) => !currentWallpaperIds.contains(w.id))
          .toList();
      
      if (mounted) {
        setState(() {
          _isLoadingWallpapers = false;
        });
        
        if (availableWallpapers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No more wallpapers available to add')),
          );
          return;
        }
        
        final selectedWallpapers = await Navigator.push<List<Wallpaper>>(
          context,
          MaterialPageRoute(
            builder: (context) => WallpaperSelectionPage(
              availableWallpapers: availableWallpapers,
            ),
          ),
        );
        
        if (selectedWallpapers != null && selectedWallpapers.isNotEmpty) {
          for (final wallpaper in selectedWallpapers) {
            await CollectionService().addWallpaperToCollection(
              widget.collection.id,
              wallpaper.id,
            );
          }
          
          setState(() {
            _wallpapers.addAll(selectedWallpapers);
          });
          _checkForChanges();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWallpapers = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading wallpapers: $e')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_isProcessing) return;
    
    if (!_hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save')),
      );
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
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
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection updated!')),
        );
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating collection: $e')),
        );
      }
    }
  }

  void _confirmDeleteCollection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection'),
        content: const Text('Are you sure you want to delete this collection? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isProcessing
                ? null
                : () async {
                    Navigator.pop(context);
                    setState(() {
                      _isRemoving = true;
                    });
                    try {
                      await CollectionService().deleteCollection(widget.collection.id);
                      if (mounted) {
                        setState(() {
                          _isRemoving = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Collection deleted!')),
                        );
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isRemoving = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error deleting collection: $e')),
                        );
                      }
                    }
                  },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Edit Collection'),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 0.0),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _isProcessing ? null : _confirmDeleteCollection,
                  tooltip: 'Delete Collection',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: (_hasChanges && !_isProcessing) ? _saveChanges : null,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            physics: _isProcessing
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            child: AbsorbPointer(
              absorbing: _isProcessing,
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
                            width: 280,
                            height: 160,
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
                          'Collection Wallpapers',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            // Button to select existing wallpapers
                            ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _selectExistingWallpapers,
                              icon: const Icon(Icons.collections),
                              label: const Text('Select'),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Button to upload new wallpaper
                            ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _pickAndUploadWallpaper,
                              icon: const Icon(Icons.add_photo_alternate_rounded),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Show appropriate progress indicators
                    if (_isUploadingWallpaper || _isLoadingWallpapers || _isRemoving)
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
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeWallpaperFromCollection(w),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Full-screen loading overlay for saving
        if (_isSaving)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  elevation: 8.0,
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16.0),
                        Text('Saving collection...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
