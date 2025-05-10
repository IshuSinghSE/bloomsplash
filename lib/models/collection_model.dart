// This file defines a Dart class named `Collection` that represents a collection of wallpapers.
class Collection {
  final String id;
  final String name;
  final String description;
  final String coverImageUrl;
  final String createdBy;
  final List<String> tags;
  final String type;
  final List<String> wallpaperIds;
  final String createdAt;

  Collection({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.createdBy,
    required this.tags,
    required this.type,
    required this.wallpaperIds,
    required this.createdAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      coverImageUrl: json['coverImageUrl'],
      createdBy: json['createdBy'],
      tags: List<String>.from(json['tags']),
      type: json['type'],
      wallpaperIds: List<String>.from(json['wallpaperIds']),
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'createdBy': createdBy,
      'tags': tags,
      'type': type,
      'wallpaperIds': wallpaperIds,
      'createdAt': createdAt,
    };
  }
}
