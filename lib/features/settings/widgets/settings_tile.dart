import 'package:flutter/material.dart';

/// Enum to define the type of settings tile
enum SettingsTileType {
  action, // For tiles that perform an action when tapped
  dialog, // For tiles that show a dialog when tapped
}

/// A reusable settings tile widget that can be used for actions or dialogs
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? customSubtitle;
  final SettingsTileType type;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool disabled;
  
  // For dialog type
  final String? dialogTitle;
  final Widget? dialogContent;
  
  const SettingsTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.customSubtitle,
    required this.type,
    this.onTap,
    this.trailing,
    this.disabled = false,
    this.dialogTitle,
    this.dialogContent,
  }) : assert(
          (type == SettingsTileType.dialog && dialogTitle != null && dialogContent != null) ||
          type == SettingsTileType.action,
          'Dialog title and content must be provided for dialog type tiles',
        );

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor,
      ),
      title: Text(title),
      subtitle: customSubtitle ?? (subtitle != null ? Text(subtitle!) : null),
      trailing: trailing,
      onTap: disabled
          ? null
          : () {
              if (type == SettingsTileType.action) {
                if (onTap != null) onTap!();
              } else {
                _showDialog(context);
              }
            },
    );
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle!),
        content: dialogContent,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
