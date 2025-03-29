import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:timely/components/button.dart';
import 'package:timely/components/labels.dart';
import 'dart:convert';
import '../auth/auth_service.dart' as auth_service;
import '../components/bottom_nav_bar.dart';
import '../components/custom_snack_bar.dart';
import '../components/text_field.dart';
import '../models/notebook.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;


  Future<void> _login() async {
    if (_usernameController.text
        .trim()
        .isEmpty) {
      showAnimatedSnackBar(
          context, "Username cannot be empty", isError: true, isTop: true);
      return;
    } else if (_passwordController.text
        .trim()
        .isEmpty) {
      showAnimatedSnackBar(
          context, "Password cannot be empty", isError: true, isTop: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
        'https://timely.pythonanywhere.com/api/v1/api-login/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _usernameController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      FocusScope.of(context).unfocus();
      final Map<String, dynamic> data = jsonDecode(response.body);

      final String? token = data['token'];
      final int? userId = data['user_id'];
      final String? username = data['username'];

      if (token == null || userId == null || username == null) {
        throw Exception(
            "Invalid response from server. Missing required fields.");
      }

      print("Token: $token");
      print("User ID: $userId");
      print("username: $username");

      await auth_service.AuthService.saveToken(token);
      await auth_service.AuthService.saveUserDetails(userId, username);

      // Fetch notebooks
      await _fetchNotebooks(token);

      if (mounted) {
        showAnimatedSnackBar(
            context, "Login Sucessfully", isSuccess: true, isTop: true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const BottomNavBar(currentIndex: 0,)),
        );
      }
    } else {
      showAnimatedSnackBar(
          context, "Invalid credentials", isError: true, isTop: true);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchNotebooks(String token) async {

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
        //print("Notebook Data: ${jsonEncode(data)}");

        // Ensure items in 'data' are maps before conversion
        List<Notebook> notebooks = data
            .where((item) => item is Map<String, dynamic>)
            .map((item) => Notebook.fromJson(item as Map<String, dynamic>))
            .toList();

        // Store notebooks locally
        await auth_service.AuthService.saveNotebooksLocally(notebooks);
      } catch (e) {
        print("Error parsing response: $e");
      }
    } else {
      print("Failed to fetch notebooks: ${response.body}");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child: Icon(Icons.login, size: 65, color: Theme
                  .of(context)
                  .colorScheme
                  .primary),
            ),
            MyLabel(text: "Login", color: Theme
                .of(context)
                .colorScheme
                .primary, size: 80, isTitle: true,),
            MyTextField(
              controller: _usernameController,
              hintext: "Enter your Username",
              obscuretext: false,
              width: 80,
              height: 20,
              maxlines: 1,
              prefixicon: Icon(Icons.person),
            ),
            MyTextField(
              controller: _passwordController,
              hintext: "Enter your password",
              obscuretext: true,
              width: 80,
              height: 20,
              maxlines: 1,
              prefixicon: Icon(Icons.lock),
            ),
            _isLoading
                ? Padding(padding: const EdgeInsets.all(8.0),
                child: Center(child: const CircularProgressIndicator()))
                : MyButton(onPressed: _login, text: "Login"),
          ],
        ),
      ),
    );
  }
}
