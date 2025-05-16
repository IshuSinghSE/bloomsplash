import 'package:flutter/material.dart';
import '../../../models/collection_model.dart';

class CollectionPage extends StatelessWidget {
  final Collection collection;

  const CollectionPage({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(collection.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            collection.coverImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Description: ${collection.description}'),
                const SizedBox(height: 8),
                Text('Tags: ${collection.tags.join(', ')}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
