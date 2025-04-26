import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserStorageHelper {
  static const _userKey = 'user_details';

  /// Save all user details in a single JSON entry
  static Future<void> saveUserDetailsAll({
    required int userId,
    required String username,
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final userMap = {
      'user_id': userId,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };

    await prefs.setString(_userKey, jsonEncode(userMap));
  }

  /// Retrieve the full user details map
  static Future<Map<String, dynamic>?> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getUserDetailsByKey(String key) async {
    final user = await getUserDetails();
    return user?[key] != null ? {key: user![key]} : null;
  }

  static Future<Map<String, dynamic>?> getUserDetailsByKeys(List<String> keys) async {
    final user = await getUserDetails();
    if (user == null) return null;
    final filteredUser = <String, dynamic>{};
    for (var key in keys) {
      if (user.containsKey(key)) {
        filteredUser[key] = user[key];
      }
    }
    return filteredUser.isNotEmpty ? filteredUser : null;
  }

  // fetch the user by profile id
  /// Clear user details
  static Future<void> clearUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  /// Get individual field by key
  static Future<String?> getUsername() async {
    final user = await getUserDetails();
    return user?["username"];
  }

  static Future<int?> getUserId() async {
    final user = await getUserDetails();
    return user?["user_id"];
  }

  static Future<String?> getEmail() async {
    final user = await getUserDetails();
    return user?["email"];
  }

  static Future<String?> getFirstName() async {
    final user = await getUserDetails();
    return user?["first_name"];
  }

  static Future<String?> getLastName() async {
    final user = await getUserDetails();
    return user?["last_name"];
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey);
  }
}
