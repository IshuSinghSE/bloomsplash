// Category model for Firestore and app features
import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String iconUrl;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
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
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconUrl': iconUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
