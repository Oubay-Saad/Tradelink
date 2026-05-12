import 'user.dart';

class ServiceItem {
  final String id;
  final String title;
  final List<String> jobTypes;
  final String description;
  final num budget;
  final List<String> images;
  final dynamic createdBy;
  final DateTime? createdAt;

  ServiceItem({
    required this.id,
    required this.title,
    required this.jobTypes,
    required this.description,
    required this.budget,
    required this.images,
    required this.createdBy,
    this.createdAt,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      jobTypes: List<String>.from(json['jobTypes'] ?? []),
      description: json['description'] ?? '',
      budget: json['budget'] ?? 0,
      images: List<String>.from(json['images'] ?? []),
      createdBy: json['createdBy'] is Map ? User.fromJson(json['createdBy']) : json['createdBy'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}
