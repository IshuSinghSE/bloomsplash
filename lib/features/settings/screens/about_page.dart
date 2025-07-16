import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constant/links.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Policies'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          _CustomExpansionTile(
            title: 'Privacy Policy',
            icon: Icons.privacy_tip_outlined,
            children: [
              const Text('Read our Privacy Policy for details on how we handle your data.'),
              const SizedBox(height: 8),
              _LinkButton(
                text: 'View Privacy Policy',
                url: AppLinks.privacyPolicy,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CustomExpansionTile(
            title: 'Terms & Conditions',
            icon: Icons.gavel_outlined,
            children: [
              const Text('Please review our Terms & Conditions before using the app.'),
              const SizedBox(height: 8),
              _LinkButton(
                text: 'View Terms & Conditions',
                url: AppLinks.termsAndConditions,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CustomExpansionTile(
            title: 'Terms of Use',
            icon: Icons.rule_folder_outlined,
            children: [
              const Text('By using BloomSplash, you agree to our Terms of Use and community guidelines.'),
              const SizedBox(height: 8),
              _LinkButton(
                text: 'Request Data Deletion',
                url: AppLinks.dataDeletion,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CustomExpansionTile(
            title: 'Contact Us',
            icon: Icons.mail_outline,
            children: [
              const Text(
                'We’re here to help!\n\n'
                'For feedback, support, or any questions, reach out:\n'
                'Email: devindeed.dev@gmail.com\n\n'
                'We usually respond within 24–48 hours. Thank you for supporting BloomSplash!',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CustomExpansionTile(
            title: 'About',
            icon: Icons.info_outline,
            children: [
              const Text(
                'BloomSplash is a modern, high-quality wallpaper application designed to inspire and personalize your device.\n\n'
                'Our mission is to deliver a curated collection of original, beautiful wallpapers, making it easy for users to discover and set the perfect background for any mood or style.\n\n'
                'Developed and maintained by the BloomSplash Team, we are committed to quality, privacy, and a seamless user experience.\n\n'
                'Key Features:\n'
                '- Handpicked, high-resolution wallpapers\n'
                '- Fast, secure, and privacy-focused\n'
                '- Powered by Flutter, Firebase, and Appwrite\n\n'
                'BloomSplash is built with open-source technologies and the support of a passionate community.\n\n'
                'For more information, licensing, or to contribute, please visit our website or contact us.\n\n'
                '© 2025 BloomSplash. All rights reserved.',
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

/// A simple button that opens a URL in the browser.
class _LinkButton extends StatelessWidget {
  final String text;
  final String url;

  const _LinkButton({required this.text, required this.url});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.open_in_new, size: 18),
      label: Text(text),
      onPressed: () async {
        final uri = Uri.tryParse(url);
        if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid or unsupported link.')),
          );
          return;
        }
        try {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!launched) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open the link.')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening link: $e')),
          );
        }
      },
    );
  }
}