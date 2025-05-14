import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../app/providers/auth_provider.dart';
import '../../my_uploads/screens/my_uploads_page.dart';
import '../../../app/providers/favorites_provider.dart'; // Ensure this is the correct path to FavoritesProvider

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  int _cacheSize = 0; // Cache size in bytes
  bool _isSyncingFavorites = false;
  late final AnimationController _syncController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void initState() {
    super.initState();
    _updateCacheSize(); // Calculate cache size on initialization
  }

  @override
  void dispose() {
    _syncController.dispose();
    super.dispose();
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
            leading: AnimatedBuilder(
              animation: _syncController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _syncController.value * 6.28319, // 2*pi radians
                  child: child,
                );
              },
              child: const Icon(Icons.sync),
            ),
            title: const Text('Sync Favorites'),
            subtitle: const Text('Sync your favourites across all your devices'),
            onTap: _isSyncingFavorites
                ? null
                : () async {
                    setState(() {
                      _isSyncingFavorites = true;
                    });
                    _syncController.repeat();
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
                    final uid = authProvider.user?.uid;
                    if (uid != null) {
                      await favoritesProvider.saveFavoritesToFirestore(uid);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Favorites synced to cloud!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You must be logged in to sync favorites.')),
                      );
                    }
                    _syncController.stop();
                    setState(() {
                      _isSyncingFavorites = false;
                    });
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