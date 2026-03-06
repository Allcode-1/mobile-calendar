class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawProfile = json['profile'];
    final profile = rawProfile is Map<String, dynamic>
        ? rawProfile
        : <String, dynamic>{};

    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: profile['full_name']?.toString() ?? '',
      avatarUrl: profile['avatar_url']?.toString(),
    );
  }
}
