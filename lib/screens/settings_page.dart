import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/auth_provider.dart';
import 'favorites_page.dart';
import 'my_uploads_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _cacheSize = 0; // Cache size in bytes

  @override
  void initState() {
    super.initState();
    _updateCacheSize(); // Calculate cache size on initialization
  }

  Future<void> _updateCacheSize() async {
    try {
      final cacheDirPath =
          await getTemporaryDirectory(); // Get the temporary directory path
      final cacheDir = Directory(
        cacheDirPath.path,
      ); // Create a Directory object
      if (await cacheDir.exists()) {
        final size = cacheDir
            .listSync(recursive: true)
            .whereType<File>()
            .fold<int>(0, (sum, file) => sum + file.lengthSync());
        setState(() {
          _cacheSize = size; // Update the cache size
        });
      } else {
        setState(() {
          _cacheSize = 0; // Set cache size to 0 if directory doesn't exist
        });
      }
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      setState(() {
        _cacheSize = 0; // Fallback to 0 on error
      });
    }
  }

  Future<void> _clearCache() async {
    try {
      final cacheDir = Directory(
        (await getTemporaryDirectory()).path,
      ); // Get the cache directory
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await _updateCacheSize(); // Recalculate cache size after clearing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image cache cleared successfully!')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No cache to clear!')));
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to clear cache!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    var preferencesBox = Hive.box('preferences');
    var userData = preferencesBox.get('userData', defaultValue: {});

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color.fromARGB(255, 56, 91, 114),
                ),
              ),
              CircleAvatar(
                radius: 50,
                backgroundImage:
                    userData['photoUrl'] != null &&
                            userData['photoUrl']!.isNotEmpty
                        ? NetworkImage(userData['photoUrl']!)
                        : const AssetImage('assets/avatar/Itsycal.webp')
                            as ImageProvider,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              userData['displayName'] ?? 'Guest User',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              userData['email'] ?? 'No email available',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          if (userData['email'] == "ishu.111636@gmail.com") ...[
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('My Uploads'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyUploadsPage(),
                  ),
                );
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('My Favorites'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesPage(showAppBar: true),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Image Cache'),
            subtitle: Text(
              _cacheSize > 1024 * 1024
                  ? 'Cache size: ${(_cacheSize / (1024 * 1024)).toStringAsFixed(2)} MB'
                  : 'Cache size: ${(_cacheSize / 1024).toStringAsFixed(2)} KB',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clearCache, // Call the clear cache function
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () {
              Provider.of<AuthProvider>(
                context,
                listen: false,
              ).signOut(context);
            },
          ),
        ],
      ),
    );
  }
}
