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
  final DateTime createdAt;

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
    DateTime? createdAt,
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

    // Helper to safely cast to List<String>
    List<String> castStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    // Ensure tags and wallpaperIds are always lists
    final tagsRaw = json.containsKey('tags') && json['tags'] != null ? json['tags'] : [];
    final wallpaperIdsRaw = json.containsKey('wallpaperIds') && json['wallpaperIds'] != null ? json['wallpaperIds'] : [];

    return Collection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      coverImage: json['coverImage'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      tags: castStringList(tagsRaw),
      type: json['type'] as String? ?? '',
      wallpaperIds: castStringList(wallpaperIdsRaw),
      createdAt: createdAt,
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
      // Store as int for Hive, convert to Timestamp for Firestore if needed
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
