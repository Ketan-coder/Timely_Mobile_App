class UserModel {
  String firstName;
  String lastName;
  String email;
  String username;
  String? lastLogin;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      lastLogin: json['lastLogin'],
    );
  }

  String getUserFullName() {
    return "$firstName $lastName";
  }
}
