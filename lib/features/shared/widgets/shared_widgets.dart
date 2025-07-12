import 'package:flutter/material.dart';

Widget buildPillButton(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}

Widget buildCircularActionButton(
  IconData icon,
  String label,
  VoidCallback? onPressed, {
  bool disabled = false,
  Color iconColor = Colors.white,
}) {
  return Column(
    children: [
      ClipOval(
        child: Material(
          color: Colors.black.withOpacity(0.5),
          child: IconButton(
            icon: Icon(icon, color: iconColor),
            onPressed: disabled ? null : onPressed,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ),
    ],
  );
}