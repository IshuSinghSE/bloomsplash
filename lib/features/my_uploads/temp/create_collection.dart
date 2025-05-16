import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../models/collection_model.dart';
import '../../../app/services/firebase/collection_service.dart';
import '../../../app/services/firebase/firebase_storage.dart' as custom_storage;

class CreateCollectionPage extends StatefulWidget {
  const CreateCollectionPage({super.key});

  @override
  State<CreateCollectionPage> createState() => _CreateCollectionPageState();
}

class _CreateCollectionPageState extends State<CreateCollectionPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _uploadedImageUrl;

  Future<void> _pickAndUploadCoverImage() async {
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
      setState(() {
        _uploadedImageUrl = result['thumbnailUrl'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload cover image.')),
      );
    }

    setState(() {
      _isUploading = false;
    });
  }

  Future<void> _createCollection() async {
    if (_nameController.text.trim().isEmpty || _uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and cover image are required.')),
      );
      return;
    }

    final newCollection = Collection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      coverImage: _uploadedImageUrl!,
      createdBy: 'admin',
      tags: _tagsController.text.split(',').map((e) => e.trim()).toList(),
      type: '',
      wallpaperIds: [],
      createdAt: Timestamp.now(),
    );

    await CollectionService().createCollection(newCollection);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Collection created successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Collection')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Collection Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isUploading ? null : _pickAndUploadCoverImage,
              child: const Text('Upload Cover Image'),
            ),
            if (_isUploading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: LinearProgressIndicator(value: _uploadProgress),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createCollection,
              child: const Text('Create Collection'),
            ),
          ],
        ),
      ),
    );
  }
}
