import 'package:flutter/material.dart';

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
      ),
      body: const Center(
        child: Text(
          'Collections Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}