import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String photoURL;
  final List<String> savedWallpapers;
  final List<String> uploadedWallpapers;
  final bool isPremium;
  final DateTime? premiumPurchasedAt;
  final String authProvider; // "google" | "apple"
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoURL,
    required this.savedWallpapers,
    required this.uploadedWallpapers,
    required this.isPremium,
    required this.premiumPurchasedAt,
    required this.authProvider,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    DateTime? premiumPurchasedAt;
    if (json['premiumPurchasedAt'] is Timestamp) {
      premiumPurchasedAt = (json['premiumPurchasedAt'] as Timestamp).toDate();
    } else if (json['premiumPurchasedAt'] is int) {
      premiumPurchasedAt = DateTime.fromMillisecondsSinceEpoch(json['premiumPurchasedAt'] as int);
    } else if (json['premiumPurchasedAt'] is String) {
      premiumPurchasedAt = DateTime.tryParse(json['premiumPurchasedAt']) ?? null;
    } else if (json['premiumPurchasedAt'] is DateTime) {
      premiumPurchasedAt = json['premiumPurchasedAt'] as DateTime;
    } else {
      premiumPurchasedAt = null;
    }

    DateTime createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int);
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.tryParse(json['createdAt']) ?? DateTime.now();
    } else if (json['createdAt'] is DateTime) {
      createdAt = json['createdAt'] as DateTime;
    } else {
      createdAt = DateTime.now();
    }

    return AppUser(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoURL: json['photoURL'] ?? '',
      savedWallpapers: List<String>.from(json['savedWallpapers'] ?? []),
      uploadedWallpapers: List<String>.from(json['uploadedWallpapers'] ?? []),
      isPremium: json['isPremium'] ?? false,
      premiumPurchasedAt: premiumPurchasedAt,
      authProvider: json['authProvider'] ?? 'google',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoURL': photoURL,
      'savedWallpapers': savedWallpapers,
      'uploadedWallpapers': uploadedWallpapers,
      'isPremium': isPremium,
      'premiumPurchasedAt': premiumPurchasedAt?.millisecondsSinceEpoch,
      'authProvider': authProvider,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
