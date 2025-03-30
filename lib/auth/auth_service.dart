import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/models/todo.dart';

import '../models/notebook.dart';
import 'package:http/http.dart' as http;

import '../models/reminder.dart';

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

  static Future<void> fetchNotebooks(String token) async {
    final url = Uri.parse(
        'https://timely.pythonanywhere.com/api/v1/notebooks/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    print("Raw API Response: ${response.body}"); // Debugging

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Validate 'results' key exists and is a list
        if (!jsonResponse.containsKey('results') ||
            jsonResponse['results'] is! List) {
          print("Error: 'results' key missing or not a List in response");
          return;
        }

        final List<dynamic> data = jsonResponse['results'];

        print("Notebooks fetched successfully!");
        print("Notebook Data: ${jsonEncode(data)}");

        // Ensure items in 'data' are maps before conversion
        List<Notebook> notebooks = data
            .where((item) => item is Map<String, dynamic>)
            .map((item) => Notebook.fromJson(item as Map<String, dynamic>))
            .toList();

        // Store notebooks locally
        await saveNotebooksLocally(notebooks);
      } catch (e) {
        print("Error parsing response: $e");
      }
    } else {
      print("Failed to fetch notebooks: ${response.body}");
    }
  }

  static Future<void> fetchTodos(String token) async {
    final url = Uri.parse(
        'https://timely.pythonanywhere.com/api/v1/todos/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    print("Raw API Response: ${response.body}"); // Debugging

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Validate 'results' key exists and is a list
        if (!jsonResponse.containsKey('results') ||
            jsonResponse['results'] is! List) {
          print("Error: 'results' key missing or not a List in response");
          return;
        }

        final List<dynamic> data = jsonResponse['results'];

        print("Todos fetched successfully!");
        print("Todos Data: ${jsonEncode(data)}");

        // Ensure items in 'data' are maps before conversion
        List<Todo> todos = data
            .where((item) => item is Map<String, dynamic>)
            .map((item) => Todo.fromJson(item as Map<String, dynamic>))
            .toList();

        // Store notebooks locally
        await saveTodoLocally(todos);
      } catch (e) {
        print("Error parsing response: $e");
      }
    } else {
      print("Failed to fetch todos: ${response.body}");
    }
  }

  static Future<void> saveTodoLocally(List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = Todo.encode(todos);
    await prefs.setString('todos', encodedData);
  }

  static Future<List<Todo>> loadTodoFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String? todoData = prefs.getString('todos');

    if (todoData != null) {
      return Todo.decode(todoData);
    }
    return [];
  }

  static Future<void> fetchReminders(String token) async {
    final url = Uri.parse(
        'https://timely.pythonanywhere.com/api/v1/remainders/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    print("Raw API Response: ${response.body}"); // Debugging

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Validate 'results' key exists and is a list
        if (!jsonResponse.containsKey('results') ||
            jsonResponse['results'] is! List) {
          print("Error: 'results' key missing or not a List in response");
          return;
        }

        final List<dynamic> data = jsonResponse['results'];

        print("Todos fetched successfully!");
        print("Todos Data: ${jsonEncode(data)}");

        // Ensure items in 'data' are maps before conversion
        List<Reminder> reminders = data
            .where((item) => item is Map<String, dynamic>)
            .map((item) => Reminder.fromJson(item as Map<String, dynamic>))
            .toList();

        // Store notebooks locally
        await saveRemindersLocally(reminders);
      } catch (e) {
        print("Error parsing response: $e");
      }
    } else {
      print("Failed to fetch todos: ${response.body}");
    }
  }

  static Future<void> saveRemindersLocally(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = Reminder.encode(reminders);
    await prefs.setString('reminders', encodedData);
  }

  static Future<List<Reminder>> loadRemindersFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String? reminderData = prefs.getString('reminders');

    if (reminderData != null) {
      return Reminder.decode(reminderData);
    }
    return [];
  }

  // static Future<Map<String, dynamic>?> fetchNotebookDetails(String token, int notebookId) async {
  //   final url = Uri.parse(
  //     'https://timely.pythonanywhere.com/api/v1/notebooks/$notebookId/',
  //   );
  //   final response = await http.get(
  //     url,
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Token $token', // Replace with actual token
  //     },
  //   );
  //
  //   if (response.statusCode == 200) {
  //     Map<String, dynamic>? notebookData = jsonDecode(response.body);
  //     return notebookData;
  //   } else {
  //     Map<String, dynamic>? notebookData = [] as Map<String, dynamic>?;
  //     return notebookData;
  //   }
  // }

  static Future<Map<String, dynamic>?> fetchPageDetails(String uuid, String token) async {
    final url = Uri.parse('https://timely.pythonanywhere.com/api/v1/pages/$uuid/');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<void> savePagesLocally(int notebookId, List<Map<String, dynamic>> pages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notebook_$notebookId', jsonEncode(pages));
  }

  static Future<List<Map<String, dynamic>>> getSavedPages(int notebookId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('notebook_$notebookId');
    return savedData != null ? List<Map<String, dynamic>>.from(jsonDecode(savedData)) : [];
  }
}
