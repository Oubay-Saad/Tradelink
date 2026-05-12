class User {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String? profilePic;
  final String? bio;
  final String? location;
  final TradesmanInfo? tradesmanInfo;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.profilePic,
    this.bio,
    this.location,
    this.tradesmanInfo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer',
      profilePic: json['profilePic'],
      bio: json['bio'],
      location: json['location'],
      tradesmanInfo: json['tradesmanInfo'] != null
          ? TradesmanInfo.fromJson(json['tradesmanInfo'])
          : null,
    );
  }
}

class TradesmanInfo {
  final List<String> jobTypes;
  final List<String> skills;
  final int? experience;
  final List<dynamic> gallery;

  TradesmanInfo({
    required this.jobTypes,
    required this.skills,
    this.experience,
    required this.gallery,
  });

  factory TradesmanInfo.fromJson(Map<String, dynamic> json) {
    return TradesmanInfo(
      jobTypes: List<String>.from(json['jobTypes'] ?? []),
      skills: List<String>.from(json['skills'] ?? []),
      experience: json['experience'],
      gallery: json['gallery'] ?? [],
    );
  }
}
