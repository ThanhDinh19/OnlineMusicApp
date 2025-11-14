class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String? avatarFirstTime;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    this.avatarFirstTime,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
        id: json['id'].toString() ?? '',
        name: json['username'] ?? '',
        email: json['email'] ?? '',
        avatar: json['avatar_url'] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }
}
