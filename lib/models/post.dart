import 'user.dart';

class Post {
  final String id;
  final String title;
  final String? description;
  final List<String> images;
  final dynamic postedBy;
  final DateTime? createdAt;

  Post({
    required this.id,
    required this.title,
    this.description,
    required this.images,
    required this.postedBy,
    this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      images: List<String>.from(json['images'] ?? []),
      postedBy: json['postedBy'] is Map ? User.fromJson(json['postedBy']) : json['postedBy'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}
