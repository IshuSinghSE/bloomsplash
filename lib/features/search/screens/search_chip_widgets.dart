import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const CategoryChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 38),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 18)),
        ],
      ),
    );
  }
}

class ColorChip extends StatelessWidget {
  final String label;
  final Color color;
  const ColorChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 28)),
        ],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String label;
  const TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: Text(label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            )),
      ),
    );
  }
}
