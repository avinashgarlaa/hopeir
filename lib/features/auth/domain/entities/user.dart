class User {
  final String userId;
  final String password;
  final String email;
  final String username;
  final String firstname;
  final String lastname;
  final String role;
  final String profilePicture;
  final String bio;

  User({
    required this.password,
    required this.firstname,
    required this.lastname,
    required this.userId,
    required this.email,
    required this.username,
    required this.role,
    required this.bio,
    required this.profilePicture,
  });

  void fold(
    Null Function(dynamic failure) param0,
    Null Function(dynamic user) param1,
  ) {}
}
