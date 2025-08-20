import 'package:hop_eir/features/auth/domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.password,
    required super.userId,
    required super.email,
    required super.username,
    required super.firstname,
    required super.lastname,
    required super.role,
    required super.bio,
    required super.profilePicture,
  });

  factory UserModel.fromProfileJson(Map<String, dynamic> json) {
    return UserModel(
      password: json["password"] ?? '',
      userId: json['user_id'] ?? '',
      email: json["email"] ?? '',
      username: json["phone_number"] ?? '',
      firstname: json["first_name"] ?? '',
      lastname: json["last_name"] ?? '',
      bio: json['bio'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      role: json['role'] ?? '',
    );
  }

  // From SuperTokens
  factory UserModel.fromSuperTokensJson(Map<String, dynamic> json) {
    return UserModel(
      userId: '',
      email: json["loginMethods"][0]["email"],
      password: "",
      username: "",
      firstname: "",
      lastname: "",
      profilePicture: "",
      bio: "",
      role: "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": userId,
      "email": email,
      "username": username,
      "first_name": firstname,
      "last_name": lastname,
      "password": password,
    };
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? username,
    String? firstname,
    String? lastname,
    String? password,
    String? role,
    String? bio,
    String? profilePicture,
  }) {
    return UserModel(
      role: role ?? this.role,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      password: password ?? this.password,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
    );
  }
}
