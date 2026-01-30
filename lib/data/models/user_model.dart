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
    final profile = json['profile'] ?? {};
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: profile['full_name'] ?? '',
      avatarUrl: profile['avatar_url'],
    );
  }
}
