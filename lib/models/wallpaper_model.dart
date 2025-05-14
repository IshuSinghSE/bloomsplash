class Wallpaper {
  final String id;
  final String name;
  final String imageUrl;
  final String thumbnailUrl;
  final int downloads;
  final int likes;
  final int size;
  final String resolution;
  final String orientation;
  final String category;
  final List<String> tags;
  final List<String> colors;
  final String author;
  final String authorImage;
  final String description;
  final bool isPremium;
  final bool isAIgenerated;
  final String status;
  final String createdAt;
  final String license;
  final String hash;

  Wallpaper({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.downloads,
    required this.likes,
    required this.size,
    required this.resolution,
    required this.orientation,
    required this.category,
    required this.tags,
    required this.colors,
    required this.author,
    required this.authorImage,
    required this.description,
    required this.isPremium,
    required this.isAIgenerated,
    required this.status,
    required this.createdAt,
    required this.license,
    required this.hash,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image'] ?? '',
      thumbnailUrl: json['thumbnail'] ?? '',
      downloads: json['downloads'] is int ? json['downloads'] : int.tryParse(json['downloads'] ?? '0') ?? 0,
      likes: json['likes'] is int ? json['likes'] : int.tryParse(json['likes'] ?? '0') ?? 0,
      size: json['size'] is int ? json['size'] : int.tryParse(json['size'] ?? '0') ?? 0,
      resolution: json['resolution'] ?? '',
      orientation: json['orientation'] ?? '',
      category: json['category'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      colors: json['colors'] != null ? List<String>.from(json['colors']) : [],
      author: json['author'] ?? '',
      authorImage: json['authorImage'] ?? '',
      description: json['description'] ?? '',
      isPremium: json['isPremium'] ?? false,
      isAIgenerated: json['isAIgenerated'] ?? false,
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
      license: json['license'] ?? '',
      hash: json['hash'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': imageUrl,
      'thumbnail': thumbnailUrl,
      'downloads': downloads,
      'likes': likes,
      'size': size,
      'resolution': resolution,
      'orientation': orientation,
      'category': category,
      'tags': tags,
      'colors': colors,
      'author': author,
      'authorImage': authorImage,
      'description': description,
      'isPremium': isPremium,
      'isAIgenerated': isAIgenerated,
      'status': status,
      'createdAt': createdAt,
      'license': license,
      'hash': hash,
    };
  }
}
