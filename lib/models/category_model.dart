// Category model for Firestore and app features
import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String iconUrl;
  final Timestamp createdAt;

  Category({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconUrl': iconUrl,
      'createdAt': createdAt,
    };
  }
}
