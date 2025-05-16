import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase/collection_service.dart';
import '../../models/collection_model.dart';
import 'collection_detail_page.dart'; // Import the collection wallpapers page

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  final CollectionService _collectionService = CollectionService();
  List<Collection> _collections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCollections();
  }

  Future<void> _fetchCollections() async {
    setState(() => _isLoading = true);
    // Try to load from Hive cache first
    var box = await Hive.openBox('collections');
    final cached = box.get('allCollections');
    if (cached != null && cached is List) {
      _collections = List<Map<String, dynamic>>.from(cached)
          .map((e) => Collection.fromJson(e))
          .toList();
    }
    // Always fetch latest from Firestore
    final collections = await _collectionService.getAllCollections();
    setState(() {
      _collections = collections;
      _isLoading = false;
    });
    // Cache to Hive
    await box.put('allCollections', collections.map((c) => c.toJson()).toList());
  }

  Future<void> _showCollectionDialog({Collection? collection}) async {
    final nameController = TextEditingController(text: collection?.name ?? '');
    final descController = TextEditingController(text: collection?.description ?? '');
    final coverController = TextEditingController(text: collection?.coverImage ?? '');
    final tagsController = TextEditingController(text: collection?.tags.join(', ') ?? '');
    final typeController = TextEditingController(text: collection?.type ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
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
                  TextFormField(
                    controller: coverController,
                    decoration: const InputDecoration(labelText: 'Cover Image URL'),
                  ),
                  TextFormField(
                    controller: tagsController,
                    decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
                  ),
                  TextFormField(
                    controller: typeController,
                    decoration: const InputDecoration(labelText: 'Type'),
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
                final newCollection = Collection(
                  id: collection?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  coverImage: coverController.text.trim(),
                  createdBy: 'admin', // Replace with actual user
                  tags: tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  type: typeController.text.trim(),
                  wallpaperIds: collection?.wallpaperIds ?? [],
                  createdAt: collection?.createdAt ?? Timestamp.now(),
                );
                if (collection == null) {
                  await _collectionService.createCollection(newCollection);
                } else {
                  await _collectionService.updateCollection(newCollection);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Set dark background color
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collections Sections
            _buildCollectionSection('All Collections', _collections),
            _buildCollectionSection('Pro Collections', _collections.where((c) => c.type == 'pro').toList()),
            _buildCollectionSection('Free Collections', _collections.where((c) => c.type == 'free').toList()),
            _buildCollectionSection('Premium Collections', _collections.where((c) => c.type == 'premium').toList()),
            // Add bottom space
            const SizedBox(height: 80), // Adjust height as needed
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCollectionDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCollectionSection(String title, List<Collection> collections) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: title.toLowerCase().contains('free')
                        ? Colors.amber
                        : title.toLowerCase().contains('pro')
                            ? Colors.cyanAccent
                            : title.toLowerCase().contains('premium')
                            ? Colors.purpleAccent
                            : Colors.orangeAccent,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: collections.length,
              separatorBuilder: (context, i) => const SizedBox(width: 16),
              itemBuilder: (context, i) {
                final collection = collections[i];
                return GestureDetector(
                  onTap: () async {
                    final wallpapers = await _collectionService.getWallpapersForCollection(collection);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CollectionDetailPage(
                          title: collection.name,
                          author: collection.createdBy,
                          wallpapers: wallpapers.map((w) => w.toJson()).toList(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1), // Add border with subtle opacity
                        width: 1.2,
                      ),
                      image: collection.coverImage.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(collection.coverImage),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey[800],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.black.withOpacity(0.4), // Add overlay for better text visibility
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                collection.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (collection.type == 'pro')
                                const Text(
                                  'INCLUDED WITH PRO',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                        if (collection.type == 'premium')
                          Positioned(
                            right: 18,
                            top: 18,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
