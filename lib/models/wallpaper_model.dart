  
class Wallpaper {
  final String id;
  final String name;
  final String imageUrl;
  final String thumbnailUrl;
  final String previewUrl;
  final int downloads;
  final int likes;
  final int size;
  final String resolution;
  final double aspectRatio;
  final String orientation;
  final String category;
  final List<String> tags;
  final List<String> colors;
  final String author;
  final String authorImage;
  final String uploadedBy;
  final String description;
  final bool isPremium;
  final bool isAIgenerated;
  final String status;
  final String createdAt;
  final String license;
  // final String blurHash;
  final String hash;

  Wallpaper({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.previewUrl,
    required this.downloads,
    required this.likes,
    required this.size,
    required this.resolution,
    required this.aspectRatio,
    required this.orientation,
    required this.category,
    required this.tags,
    required this.colors,
    required this.author,
    required this.authorImage,
    required this.uploadedBy,
    required this.description,
    required this.isPremium,
    required this.isAIgenerated,
    required this.status,
    required this.createdAt,
    required this.license,
    // required this.blurHash,
    required this.hash,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image'],
      thumbnailUrl: json['thumbnail'],
      previewUrl: json['preview'],
      downloads: json['downloads'],
      likes: json['likes'],
      size: json['size'],
      resolution: json['resolution'],
      aspectRatio: json['aspectRatio'],
      orientation: json['orientation'],
      category: json['category'],
      tags: List<String>.from(json['tags']),
      colors: List<String>.from(json['colors']),
      author: json['author'],
      authorImage: json['authorImage'],
      uploadedBy: json['uploadedBy'],
      description: json['description'],
      isPremium: json['isPremium'],
      isAIgenerated: json['isAIgenerated'],
      status: json['status'],
      createdAt: json['createdAt'],
      license: json['license'],
      // blurHash: json['blurHash'],
      hash: json['hash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': imageUrl,
      'thumbnail': thumbnailUrl,
      'preview': previewUrl,
      'downloads': downloads,
      'likes': likes,
      'size': size,
      'resolution': resolution,
      'aspectRatio': aspectRatio,
      'orientation': orientation,
      'category': category,
      'tags': tags,
      'colors': colors,
      'author': author,
      'authorImage': authorImage,
      'uploadedBy': uploadedBy,
      'description': description,
      'isPremium': isPremium,
      'isAIgenerated': isAIgenerated,
      'status': status,
      'createdAt': createdAt,
      'license': license,
      // 'blurHash': blurHash,
      'hash': hash,
    };
  }
}
