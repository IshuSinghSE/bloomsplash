import 'package:flutter/material.dart';

// Color palette
class AppColors {
  static const Color primary = Color(0xFF385B72);            // Main brand color
  static const Color primaryLight = Color(0x1A385B72);       // 10% opacity
  static const Color primaryDark = Color(0xB8385B72);        // 70% opacity
  static const Color accent = Colors.white;                  // Accent color (text/icons)
  static const Color accentSecondary = Colors.white70;       // Secondary accent (subtle text/icons)
  static const Color chipBackground = Color(0x1A385B72);     // Chip background (10% opacity)
  static const Color chipSelected = Color(0xB8385B72);       // Chip selected (70% opacity)
  static const Color gradientStart = Color(0x99000000);      // Gradient start (60% black)
  static const Color gradientEnd = Colors.transparent;       // Gradient end (transparent)
  static const Color blurOverlay = Color(0x26385B72);        // Blur overlay (15% opacity)
  static const Color border = Color(0xC8385B72);             // Border color (78% opacity)
}

// Border radius values
class AppRadius {
  static const double card = 16.0;   // Card corners
  static const double chip = 24.0;   // Chip corners
  static const double image = 8.0;   // Image corners
}

// Text styles
class AppTextStyles {
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle cardTitle = TextStyle(
    color: AppColors.accent,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle cardSubtitle = TextStyle(
    color: AppColors.accentSecondary,
    fontSize: 12,
  );
  static const TextStyle button = TextStyle(
    color: AppColors.accent,
  );
}
