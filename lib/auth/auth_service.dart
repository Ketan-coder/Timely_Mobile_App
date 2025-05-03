import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/components/custom_snack_bar.dart';
import 'package:timely/models/shared_notebook.dart';
import 'package:timely/models/todo.dart';
import 'package:timely/models/user_preference.dart';
import 'package:timely/services/internet_checker_service.dart';

import '../models/notebook.dart';
import 'package:http/http.dart' as http;

import '../models/profile.dart';
import '../models/reminder.dart';
import '../models/user.dart';

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

  // Saving a single notebook (Map)
  static Future<void> saveNotebookLocally(int notebookId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notebook_$notebookId', jsonEncode(data));
  }

  // Loading the same single notebook
  static Future<Map<String, dynamic>?> loadNotebookFromLocal(int notebookId) async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('notebook_$notebookId');
    if (data != null) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return null;
  }



  static Future<void> fetchNotebooks(String token, InternetChecker internetChecker, {int? pageNumber}) async {
    if (!internetChecker.isConnected) {
      print("No internet connection. Skipping API call.");
      showAnimatedSnackBar(
        internetChecker.context,
        "You're offline. Please check your internet connection.",
        isError: true,
        isTop: true,
      );
      return;
    }

    final Uri url;
    if (pageNumber == null || pageNumber == 1) {
      url = Uri.parse('https://timely.pythonanywhere.com/api/v1/notebooks/');
    } else {
      url = Uri.parse('https://timely.pythonanywhere.com/api/v1/notebooks/?page=$pageNumber');
    }

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      print("Raw API Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (!jsonResponse.containsKey('results') || jsonResponse['results'] is! List) {
          print("Error: 'results' key missing or not a List in response");
          return;
        }

        final List<dynamic> data = jsonResponse['results'];

        print("Notebooks fetched successfully!");
        print("Notebook Data: ${jsonEncode(data)}");

        List<Notebook> notebooks = data
            .where((item) => item is Map<String, dynamic>)
            .map((item) => Notebook.fromJson(item as Map<String, dynamic>))
            .toList();

        await saveNotebooksLocally(notebooks);
      } else {
        print("Failed to fetch notebooks: ${response.body}");
      }
    } on SocketException catch (e) {
      print("No internet or DNS issue: $e");
    } catch (e) {
      print("Unexpected error during API call: $e");
    }
  }


  static Future<List<SharedNotebook>> fetchSharedNotebooksByNotebookId(
      String token, int notebookId) async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/sharednotebooks/',
    ).replace(
      queryParameters: {'notebook': '$notebookId'},
    );

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
          return [];
        }

        final List<dynamic> data = jsonResponse['results'];

        print("Shared Notebooks fetched successfully!");
        print("Shared Notebooks Data ==> ${jsonEncode(data)}");

        // Ensure items in 'data' are maps before conversion
        List<SharedNotebook> sharedNotebooks = data
            .where((item) => item is Map<String, dynamic>)
            .map((item) =>
            SharedNotebook.fromJson(item as Map<String, dynamic>))
            .toList();

        return sharedNotebooks;
      } catch (e) {
        print("Error parsing response: $e");
      }
    } else {
      print("Failed to fetch shared notebooks: ${response.body}");
    }

    return []; // If error, return empty list
  }


  static Future<void> fetchSharedNotebooks(String token, InternetChecker _internetChecker) async {
      if (!_internetChecker.isConnected) {
        print("No internet connection. Skipping API call.");
        showAnimatedSnackBar(
          _internetChecker.context,
          "You're offline. Please check your internet connection.",
          isError: true,
          isTop: true,
        );
        return;
      }

      final Uri url = Uri.parse('https://timely.pythonanywhere.com/api/v1/notebooks/')
          .replace(queryParameters: {'shared_with_me': 'True'});

      try {
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        );

        print("Raw API Response: ${response.body}");

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

          if (!jsonResponse.containsKey('results') || jsonResponse['results'] is! List) {
            print("Error: 'results' key missing or not a List in response");
            return;
          }

          final List<dynamic> data = jsonResponse['results'];
          print("Shared notebooks fetched successfully!");
          print("Notebook Data: ${jsonEncode(data)}");

          List<Notebook> notebooks = data
              .where((item) => item is Map<String, dynamic>)
              .map((item) => Notebook.fromJson(item as Map<String, dynamic>))
              .toList();

          await saveSharedNotebooksLocally(notebooks);
        } else {
          print("Failed to fetch shared notebooks: ${response.statusCode} - ${response.body}");
          showAnimatedSnackBar(
            _internetChecker.context,
            "Failed to fetch shared notebooks: ${response.statusCode}",
            isError: true,
            isTop: true,
          );
        }
      } on SocketException catch (e) {
        print("Network error: $e");
        showAnimatedSnackBar(
          _internetChecker.context,
          "Cannot reach server. Please check your internet.",
          isError: true,
          isTop: true,
        );
      } catch (e) {
        print("Unexpected error: $e");
        showAnimatedSnackBar(
          _internetChecker.context,
          "Something went wrong while fetching shared notebooks.",
          isError: true,
          isTop: true,
        );
      }
    }

  static Future<void> saveSharedNotebooksLocally(
      List<Notebook> notebooks) async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = Notebook.encode(notebooks);
    await prefs.setString('shared_notebooks', encodedData);
  }

  static Future<List<Notebook>> loadSharedNotebooksFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String? notebookData = prefs.getString('shared_notebooks');

    if (notebookData != null) {
      return Notebook.decode(notebookData);
    }
    return [];
  }

  static Future<void> fetchPublicNotebooks(String token, InternetChecker _internetChecker) async {
    if (!_internetChecker.isConnected) {
      print("No internet connection. Skipping API call.");
      showAnimatedSnackBar(
        _internetChecker.context,
        "You're offline. Please check your internet connection.",
        isError: true,
        isTop: true,
      );
      return;
    }

    final Uri url = Uri.parse('https://timely.pythonanywhere.com/api/v1/notebooks/')
        .replace(queryParameters: {'is_public': 'True'});

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      print("Raw API Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (!jsonResponse.containsKey('results') || jsonResponse['results'] is! List) {
          print("Error: 'results' key missing or not a List in response");
          return;
        }

        final List<dynamic> data = jsonResponse['results'];
        print("Public notebooks fetched successfully!");
        print("Public Notebook Data: ${jsonEncode(data)}");

        List<Notebook> notebooks = data
            .where((item) => item is Map<String, dynamic>)
            .map((item) => Notebook.fromJson(item as Map<String, dynamic>))
            .toList();

        await savePublicNotebooksLocally(notebooks);
      } else {
        print("Failed to fetch public notebooks: ${response.statusCode} - ${response.body}");
        showAnimatedSnackBar(
          _internetChecker.context,
          "Failed to fetch public notebooks: ${response.statusCode}",
          isError: true,
          isTop: true,
        );
      }
    } on SocketException catch (e) {
      print("Network error: $e");
      showAnimatedSnackBar(
        _internetChecker.context,
        "Cannot reach server. Please check your internet.",
        isError: true,
        isTop: true,
      );
    } catch (e) {
      print("Unexpected error: $e");
      showAnimatedSnackBar(
        _internetChecker.context,
        "Something went wrong while fetching public notebooks.",
        isError: true,
        isTop: true,
      );
    }
  }

  static Future<List<Notebook>> searchPublicNotebooks(String token,
      String searchTerm) async {
    final url = Uri.parse(
        'https://timely.pythonanywhere.com/api/v1/notebooks/').replace(
        queryParameters: {'is_public': 'True', 'search': searchTerm});
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
          return []; // Return an empty list in case of an error
        }

        final List<dynamic> data = jsonResponse['results'];

        print("Searched Notebook fetched successfully!");
        print("Searched Notebook Data ==> ${jsonEncode(data)}");

        // Ensure items in 'data' are maps before conversion
        List<Notebook> notebooks = data
            .where((item) => item is Map<String, dynamic>)
            .map((item) => Notebook.fromJson(item as Map<String, dynamic>))
            .toList();

        return notebooks; // Return the fetched notebooks
      } catch (e) {
        print("Error parsing response: $e");
        return []; // Return an empty list in case of parsing error
      }
    } else {
      print("Failed to fetch searching notebooks: ${response.body}");
      return []; // Return an empty list if the API call fails
    }
  }

  static Future<List<Notebook>> searchSharedNotebooks(String token,
      String searchTerm) async {
    final url = Uri.parse(
        'https://timely.pythonanywhere.com/api/v1/notebooks/').replace(
        queryParameters: {'shared_with_me': 'True', 'search': searchTerm});
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
          return []; // Return an empty list in case of an error
        }

        final List<dynamic> data = jsonResponse['results'];

        print("Searched Notebook fetched successfully!");
        print("Searched Notebook Data ==> ${jsonEncode(data)}");

        // Ensure items in 'data' are maps before conversion
        List<Notebook> notebooks = data
            .where((item) => item is Map<String, dynamic>)
            .map((item) => Notebook.fromJson(item as Map<String, dynamic>))
            .toList();

        return notebooks; // Return the fetched notebooks
      } catch (e) {
        print("Error parsing response: $e");
        return []; // Return an empty list in case of parsing error
      }
    } else {
      print("Failed to fetch searching notebooks: ${response.body}");
      return []; // Return an empty list if the API call fails
    }
  }


  static Future<List<Notebook>> searchNotebooks(String token,
      String searchTerm) async {
    final url = Uri.parse(
        'https://timely.pythonanywhere.com/api/v1/notebooks/').replace(
        queryParameters: {'search': searchTerm});
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
          return []; // Return an empty list in case of an error
        }

        final List<dynamic> data = jsonResponse['results'];

        print("Searched Notebook fetched successfully!");
        print("Searched Notebook Data ==> ${jsonEncode(data)}");

        // Ensure items in 'data' are maps before conversion
        List<Notebook> notebooks = data
            .where((item) => item is Map<String, dynamic>)
            .map((item) => Notebook.fromJson(item as Map<String, dynamic>))
            .toList();

        return notebooks; // Return the fetched notebooks
      } catch (e) {
        print("Error parsing response: $e");
        return []; // Return an empty list in case of parsing error
      }
    } else {
      print("Failed to fetch searching notebooks: ${response.body}");
      return []; // Return an empty list if the API call fails
    }
  }


  static Future<void> savePublicNotebooksLocally(
      List<Notebook> notebooks) async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = Notebook.encode(notebooks);
    await prefs.setString('public_notebooks', encodedData);
  }

  static Future<List<Notebook>> loadPublicNotebooksFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String? notebookData = prefs.getString('public_notebooks');

    if (notebookData != null) {
      return Notebook.decode(notebookData);
    }
    return [];
  }

  static Future<void> fetchTodos(String token, InternetChecker _internetChecker) async {
    if (!_internetChecker.isConnected) {
      print("No internet connection. Skipping API call.");
      showAnimatedSnackBar(
        _internetChecker.context,
        "You're offline. Please check your internet connection.",
        isError: true,
        isTop: true,
      );
      return;
    }

    final url = Uri.parse('https://timely.pythonanywhere.com/api/v1/todos/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      print("Raw API Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (!jsonResponse.containsKey('results') || jsonResponse['results'] is! List) {
          print("Error: 'results' key missing or not a List in response");
          return;
        }

        final List<dynamic> data = jsonResponse['results'];
        print("Todos fetched successfully!");
        print("Todos Data: ${jsonEncode(data)}");

        List<Todo> todos = data
            .where((item) => item is Map<String, dynamic>)
            .map((item) => Todo.fromJson(item as Map<String, dynamic>))
            .toList();

        await saveTodoLocally(todos);
      } else {
        print("Failed to fetch todos: ${response.statusCode} - ${response.body}");
        showAnimatedSnackBar(
          _internetChecker.context,
          "Failed to fetch todos: ${response.statusCode}",
          isError: true,
          isTop: true,
        );
      }
    } on SocketException catch (e) {
      print("Network error: $e");
      showAnimatedSnackBar(
        _internetChecker.context,
        "Cannot reach server. Please check your internet.",
        isError: true,
        isTop: true,
      );
    } catch (e) {
      print("Unexpected error: $e");
      showAnimatedSnackBar(
        _internetChecker.context,
        "Something went wrong while fetching your todos.",
        isError: true,
        isTop: true,
      );
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

  static Future<void> fetchReminders(String token, InternetChecker _internetChecker, {int? pageNumber}) async {
      if (!_internetChecker.isConnected) {
        print("No internet connection. Skipping API call.");
        showAnimatedSnackBar(
          _internetChecker.context,
          "You're offline. Please check your internet connection.",
          isError: true,
          isTop: true,
        );
        return;
      }

      final Uri url = Uri.parse(
        pageNumber == null || pageNumber == 1
            ? 'https://timely.pythonanywhere.com/api/v1/remainders/'
            : 'https://timely.pythonanywhere.com/api/v1/remainders/?page=$pageNumber',
      );

      try {
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        );

        print("Raw API Response: ${response.body}");

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

          if (!jsonResponse.containsKey('results') || jsonResponse['results'] is! List) {
            print("Error: 'results' key missing or not a List in response");
            return;
          }

          final List<dynamic> data = jsonResponse['results'];
          print("Reminders fetched successfully!");
          print("Reminders Data: ${jsonEncode(data)}");

          List<Reminder> reminders = data
              .where((item) => item is Map<String, dynamic>)
              .map((item) => Reminder.fromJson(item as Map<String, dynamic>))
              .toList();

          await saveRemindersLocally(reminders);
        } else {
          print("Failed to fetch Reminders: ${response.statusCode} - ${response.body}");
          showAnimatedSnackBar(
            _internetChecker.context,
            "Failed to fetch reminders: ${response.statusCode}",
            isError: true,
            isTop: true,
          );
        }
      } on SocketException catch (e) {
        print("Network error: $e");
        showAnimatedSnackBar(
          _internetChecker.context,
          "Cannot reach server. Please check your internet.",
          isError: true,
          isTop: true,
        );
      } catch (e) {
        print("Unexpected error: $e");
        showAnimatedSnackBar(
          _internetChecker.context,
          "Something went wrong while fetching your reminders.",
          isError: true,
          isTop: true,
        );
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

  static Future<bool> checkIfReminderIsCompleted(int reminderId) async {
  try {
    String? token = await AuthService.getToken();
    if (token == null) {
      return false;
    }
    final url = Uri.parse(
        'https://timely.pythonanywhere.com/api/v1/remainders/$reminderId/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data);
      return data['is_completed'] ?? false; // Check if 'is_completed' key exists
    } else if (response.statusCode == 404) {
      print('[ERROR] Reminder with ID $reminderId not found.');
      return false;
    } else if (response.statusCode == 403) {
      print('[ERROR] Unauthorized access to reminder $reminderId.');
      return false;
    } else if (response.statusCode == 500) {
      print('[ERROR] Server error while checking reminder $reminderId.');
      return false;
    } else {
      print('[ERROR] Failed to fetch status for reminder $reminderId');
      return false;
    }
  } catch (e) {
    print('[EXCEPTION] Error checking completion status: $e');
    return false;
  }
}


  static Future<Map<String, dynamic>?> fetchNotebookDetails(String token,
      int notebookId) async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/notebooks/$notebookId/',
    );
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token', // Replace with actual token
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic>? notebookData = jsonDecode(response.body);
      return notebookData;
    } else {
      Map<String, dynamic>? notebookData = [] as Map<String, dynamic>?;
      return notebookData;
    }
  }

  static Future<Map<String, dynamic>?> fetchPageDetails(String uuid,
      String token) async {
    final url = Uri.parse(
        'https://timely.pythonanywhere.com/api/v1/pages/$uuid/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token'
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> fetchSubPageDetails(String uuid, String token) async {
    final url = Uri.parse('https://timely.pythonanywhere.com/api/v1/subpages/$uuid/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token'
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<void> savePagesLocally(int notebookId,
      List<Map<String, dynamic>> pages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notebook_$notebookId', jsonEncode(pages));
  }

  static Future<List<Map<String, dynamic>>> getSavedPages(
      int notebookId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('notebook_$notebookId');
    return savedData != null ? List<Map<String, dynamic>>.from(
        jsonDecode(savedData)) : [];
  }

  static Future<void> saveSubPagesLocally(int notebookId,
      List<Map<String, dynamic>> pages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notebook_subpages_$notebookId', jsonEncode(pages));
  }

  static Future<List<Map<String, dynamic>>> getSavedSubPages(
      int notebookId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('notebook_subpages_$notebookId');
    return savedData != null ? List<Map<String, dynamic>>.from(
        jsonDecode(savedData)) : [];
  }

  // ======================================== Users ========================================
  static Future<ProfileModel?> fetchUserByProfileId(String token,
      int profileId) async {
    final url = Uri.parse(
        'https://timely.pythonanywhere.com/api-auth/v1/profile/$profileId/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    print("Raw API Response: ${response.body}");

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Create ProfileModel
        final profile = ProfileModel.fromJson(jsonResponse);

        print("Profile fetched successfully!");
        print("Profile Full Name: ${profile.getProfileFullName()}");
        if (profile.user != null) {
          print("User Full Name: ${profile.user!.getUserFullName()}");
        }

        return profile;
      } catch (e) {
        print("Error parsing response: $e");
      }
    } else {
      print("Failed to fetch profile: ${response.body}");
    }
    return null;
  }

  static Future<void> saveUserLocally(int notebookId,
      List<ProfileModel> users) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> userList = users.map((user) =>
    {
      'id': user.id,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'email': user.email,
      'bio': user.bio,
      'emailConfirmationToken': user.emailConfirmationToken,
      'userId': user.userId,
      'user': user.user != null
          ? {
        'first_name': user.user!.firstName,
        'last_name': user.user!.lastName,
        'email': user.user!.email,
        'username': user.user!.username,
        'lastLogin': user.user!.lastLogin,
      }
          : null,
    }).toList();

    String jsonString = jsonEncode(userList);

    await prefs.setString('notebook_shared_users_$notebookId', jsonString);
    print('Users for notebook $notebookId saved locally!');
  }

  static Future<List<ProfileModel>> getUserLocally(int notebookId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(
        'notebook_shared_users_$notebookId');

    if (jsonString == null) {
      print('No users found for notebook $notebookId');
      return [];
    }

    final List<dynamic> jsonData = jsonDecode(jsonString);

    List<ProfileModel> users = jsonData.map((item) {
      return ProfileModel(
        id: item['id'],
        firstName: item['firstName'] ?? '',
        lastName: item['lastName'] ?? '',
        email: item['email'] ?? '',
        bio: item['bio'] ?? '',
        emailConfirmationToken: item['emailConfirmationToken'] ?? '',
        userId: item['userId'] ?? 0,
        user: item['user'] != null
            ? UserModel(
          firstName: item['user']['first_name'] ?? '',
          lastName: item['user']['last_name'] ?? '',
          email: item['user']['email'] ?? '',
          username: item['user']['username'] ?? '',
          lastLogin: item['user']['lastLogin'],
        )
            : null,
      );
    }).toList();

    print('Fetched ${users.length} users for notebook $notebookId!');
    return users;
  }

  Future<void> fetchUserPreferences(String token, BuildContext context) async {
    final url = Uri.parse(
        'https://timely.pythonanywhere.com/api-auth/v1/userpreference/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("User preferences fetched successfully!");
        print("User Preferences Data: ${jsonEncode(data)}");

        final List<dynamic> results = data['results'];
        if (results.isNotEmpty) {
          final prefsModel = UserPreference.fromJson(results.first);
          await saveUserPreferencesLocally(prefsModel.toJson());
        }
      } else {
        print("Failed to fetch user preferences: ${response.body}");
      }
    } on SocketException {
      print("No internet connection. Please check your network.");
      showAnimatedSnackBar(
          context, "No internet connection. Please check your network.",
          isError: true, isTop: true);
    } catch (e) {
      print("Unexpected error while fetching preferences: $e");
    }
  }

    static Future<void> saveUserPreferencesLocally(Map<String, dynamic> preferences) async {
      final prefs = await SharedPreferences.getInstance();
      String encodedData = jsonEncode(preferences);
      await prefs.setString('user_preferences', encodedData);
    }

    static Future<UserPreference?> loadUserPreferencesFromLocal() async {
      final prefs = await SharedPreferences.getInstance();
      String? preferencesData = prefs.getString('user_preferences');

      if (preferencesData != null) {
        final Map<String, dynamic> decoded = jsonDecode(preferencesData);
        return UserPreference.fromJson(decoded);
      }
      return null;
    }

  Future<void> updateUserPreferences(String token, String key, dynamic value,
      int userPreferenceId, BuildContext context) async {
    final url = Uri.parse(
        'https://timely.pythonanywhere.com/api-auth/v1/userpreference/$userPreferenceId/');
    final localTime = DateTime.now().toLocal();
    print(localTime);
    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Token $token',
        },
        body: {
          key: value.toString(),
          'updated_at': localTime.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        showAnimatedSnackBar(
            context, "Preferences updated successfully.", isSuccess: true,
            isTop: true);
      } else {
        showAnimatedSnackBar(
            context, "Failed to update preferences: ${response.body}",
            isError: true, isTop: true);
      }
    } on SocketException {
      showAnimatedSnackBar(
          context, "No internet connection. Please check your network.",
          isError: true, isTop: true);
    } catch (e) {
      showAnimatedSnackBar(
          context, "Unexpected error while updating preferences: $e",
          isError: true, isTop: true);
    }
  }

}
