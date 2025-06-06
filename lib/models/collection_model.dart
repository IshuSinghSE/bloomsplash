// This file defines a Dart class named `Collection` that represents a collection of wallpapers.
import 'package:cloud_firestore/cloud_firestore.dart';

class Collection {
  final String id;
  final String name;
  final String description;
  final String coverImage;
  final String createdBy;
  final List<String> tags;
  final String type;
  final List<String> wallpaperIds;
  final Timestamp createdAt;

  Collection({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImage,
    required this.createdBy,
    required this.tags,
    required this.type,
    required this.wallpaperIds,
    required this.createdAt,
  });

  Collection copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImage,
    String? createdBy,
    List<String>? tags,
    String? type,
    List<String>? wallpaperIds,
    Timestamp? createdAt,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      createdBy: createdBy ?? this.createdBy,
      tags: tags ?? this.tags,
      type: type ?? this.type,
      wallpaperIds: wallpaperIds ?? this.wallpaperIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      coverImage: json['coverImage'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      type: json['type'] as String? ?? '',
      wallpaperIds: List<String>.from(json['wallpaperIds'] ?? []),
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverImage': coverImage,
      'createdBy': createdBy,
      'tags': tags,
      'type': type,
      'wallpaperIds': wallpaperIds,
      'createdAt': createdAt,
    };
  }
}
