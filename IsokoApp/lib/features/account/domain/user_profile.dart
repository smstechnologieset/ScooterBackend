class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.phone,
    required this.displayName,
    required this.avatarPath,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? email;
  final String? phone;
  final String displayName;
  final String? avatarPath;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? email,
    String? displayName,
    String? avatarPath,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      phone: phone,
      displayName: displayName ?? this.displayName,
      avatarPath: avatarPath ?? this.avatarPath,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    required String? email,
    required String? phone,
  }) {
    return UserProfile(
      id: json['id'] as String,
      email: email,
      phone: phone,
      displayName: json['display_name'] as String,
      avatarPath: json['avatar_path'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
