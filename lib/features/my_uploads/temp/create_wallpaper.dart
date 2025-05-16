import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../models/wallpaper_model.dart';
import '../../../app/services/firebase/firebase_storage.dart' as custom_storage;
import '../../../app/services/firebase/firebase_firestore_service.dart';

class CreateWallpaperPage extends StatefulWidget {
  const CreateWallpaperPage({super.key});

  @override
  State<CreateWallpaperPage> createState() => _CreateWallpaperPageState();
}

class _CreateWallpaperPageState extends State<CreateWallpaperPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<void> _pickAndUploadWallpaper() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    final file = File(image.path);
    final result = await custom_storage.uploadFileToFirebaseWithProgress(
      file,
      (progress) {
        setState(() {
          _uploadProgress = progress;
        });
      },
    );

    if (result != null && result['thumbnailUrl'] != null) {
      final newWallpaper = Wallpaper(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        imageUrl: result['originalUrl'],
        thumbnailUrl: result['thumbnailUrl'],
        downloads: 0,
        likes: 0,
        size: result['originalSize'] ?? 0,
        resolution: result['originalResolution']?.toString() ?? '',
        category: '',
        author: 'admin',
        authorImage: '',
        description: '',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallpaper uploaded successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload wallpaper.')),
      );
    }

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Wallpaper')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Wallpaper Name'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isUploading ? null : _pickAndUploadWallpaper,
              child: const Text('Upload Wallpaper'),
            ),
            if (_isUploading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: LinearProgressIndicator(value: _uploadProgress),
              ),
          ],
        ),
      ),
    );
  }
}
