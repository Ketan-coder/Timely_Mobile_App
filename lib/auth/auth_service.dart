import 'package:shared_preferences/shared_preferences.dart';

import '../models/notebook.dart';

class AuthService {
  static Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveUserDetails(int userId, String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
    await prefs.setString('username', username);
  }

  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> saveNotebooksLocally(List<Notebook> notebooks) async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = Notebook.encode(notebooks);
    await prefs.setString('notebooks', encodedData);
  }

  static Future<List<Notebook>> loadNotebooksFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String? notebookData = prefs.getString('notebooks');

    if (notebookData != null) {
      return Notebook.decode(notebookData);
    }
    return [];
  }
}
