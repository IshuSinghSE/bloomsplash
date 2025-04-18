import 'package:flutter/material.dart';
import 'explore_page.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'favorites_page.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
        children: [
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
                        : const AssetImage('assets/avatar/Itsycal.png')
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
          const SizedBox(height: 24),
          // ListTile(
          //   leading: const Icon(Icons.auto_awesome),
          //   title: const Text('Auto Switch (Pro)'),
          //   trailing: Switch(value: true, onChanged: (value) {}),
          // ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('My Uploads'),
           onTap: () {
            },
          ),
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
            leading: const Icon(Icons.clear),
            title: const Text('Clear Cache'),
            subtitle: const Text('Current size: 60.2 kB'),
            onTap: () {
            },
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
