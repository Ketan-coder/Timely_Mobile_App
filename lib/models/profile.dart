// user.dart
import 'package:timely/models/user.dart';

import 'profile.dart';

class ProfileModel {
  int id;
  UserModel? user;
  String firstName;
  String lastName;
  String email;
  String bio;
  String emailConfirmationToken;
  int userId;

  ProfileModel({
    required this.id,
    this.user,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.bio,
    required this.emailConfirmationToken,
    required this.userId,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      user:
          json['profile'] != null ? UserModel.fromJson(json['profile']) : null,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'] ?? '',
      emailConfirmationToken: json['email_confirmation_token'] ?? '',
      userId: json['user'] ?? 0,
    );
  }

  String getProfileFullName() {
    return "$firstName $lastName";
  }
}
