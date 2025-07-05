import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Legal'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: const [
          _CustomExpansionTile(
            title: 'Privacy Policy',
            icon: Icons.privacy_tip_outlined,
            children: [
              Text(
                'Here is the Privacy Policy of the app. Please visit our website for the full document.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _CustomExpansionTile(
            title: 'Terms & Conditions',
            icon: Icons.gavel_outlined,
            children: [
              Text(
                'Here are the Terms & Conditions of the app. Please visit our website for the full document.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _CustomExpansionTile(
            title: 'About',
            icon: Icons.info_outline,
            children: [
              Text(
                'This app is developed by BloomSplash Team.\n\n'
                'Credits:\n'
                '- Flutter & Dart\n'
                '- Open source packages\n\n'
                'All rights reserved.\n'
                'See our website for full license details.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A styled, reusable expansion tile widget.
class _CustomExpansionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _CustomExpansionTile({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map((child) => DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 15,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                    height: 1.5,
                  ),
                  child: child,
                ))
            .toList(),
      ),
    );
  }
}