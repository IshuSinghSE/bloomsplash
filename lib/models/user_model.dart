import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String photoURL;
  final List<String> savedWallpapers;
  final List<String> uploadedWallpapers;
  final bool isPremium;
  final Timestamp? premiumPurchasedAt;
  final String authProvider; // "google" | "apple"
  final Timestamp createdAt;

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
    return AppUser(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoURL: json['photoURL'] ?? '',
      savedWallpapers: List<String>.from(json['savedWallpapers'] ?? []),
      uploadedWallpapers: List<String>.from(json['uploadedWallpapers'] ?? []),
      isPremium: json['isPremium'] ?? false,
      premiumPurchasedAt: json['premiumPurchasedAt'],
      authProvider: json['authProvider'] ?? 'google',
      createdAt: json['createdAt'] ?? Timestamp.now(),
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
      'premiumPurchasedAt': premiumPurchasedAt,
      'authProvider': authProvider,
      'createdAt': createdAt,
    };
  }
}
