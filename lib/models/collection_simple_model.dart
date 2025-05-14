import 'package:cloud_firestore/cloud_firestore.dart';

class Collection {
  final String id;
  final String title;
  final String description;
  final List<String> wallpaperIds;
  final String coverImage;
  final Timestamp createdAt;

  Collection({
    required this.id,
    required this.title,
    required this.description,
    required this.wallpaperIds,
    required this.coverImage,
    required this.createdAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      wallpaperIds: List<String>.from(json['wallpaperIds'] ?? []),
      coverImage: json['coverImage'] ?? '',
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'wallpaperIds': wallpaperIds,
      'coverImage': coverImage,
      'createdAt': createdAt,
    };
  }
}
