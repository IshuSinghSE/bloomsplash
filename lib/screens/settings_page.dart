import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
              radius: 52, // Outer circle radius
              backgroundColor: Colors.white, // White border color
              child: CircleAvatar(
                radius: 50, // Inner circle radius
                backgroundColor: const Color.fromARGB(255, 56, 91, 114),
              ),
              ),
              const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/avatar/Itsycal.png'),
              ),
            ],
            ),

          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Ishu Singh',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const Center(
            child: Text(
              'example@email.com',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          // ListTile(
          //   leading: const Icon(Icons.auto_awesome),
          //   title: const Text('Auto Switch (Pro)'),
          //   trailing: Switch(value: true, onChanged: (value) {}),
          // ),
          // ListTile(
          //   leading: const Icon(Icons.upload),
          //   title: const Text('My Uploads'),
          //   onTap: () {},
          // ),
          // ListTile(
          //   leading: const Icon(Icons.favorite),
          //   title: const Text('My Favorites'),
          //   onTap: () {},
          // ),
          ListTile(
            leading: const Icon(Icons.clear),
            title: const Text('Clear Cache'),
            subtitle: const Text('Current size: 60.2 kB'),
            onTap: () {},
          ),
          // ListTile(
          //   leading: const Icon(Icons.sync),
          //   title: const Text('Sync Favorites'),
          //   onTap: () {},
          // ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
