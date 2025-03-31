import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_service.dart' as auth_service;
import '../components/bottom_nav_bar.dart';
import '../components/button.dart';
import '../components/custom_page_animation.dart';
import '../components/custom_snack_bar.dart';
import '../components/labels.dart';
import '../components/text_field.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  bool _isLoading = false;

  // Not completed, because API isn't Build for this!
  Future<void> _signUp() async {
    if (_usernameController.text.trim().isEmpty) {
      showAnimatedSnackBar(
        context,
        "Username cannot be empty",
        isError: true,
        isTop: true,
      );
      return;
    } else if (_passwordController.text.trim().isEmpty) {
      showAnimatedSnackBar(
        context,
        "Password cannot be empty",
        isError: true,
        isTop: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/api-login/',
    );
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
          "Invalid response from server. Missing required fields.",
        );
      }

      print("Token: $token");
      print("User ID: $userId");
      print("username: $username");

      await auth_service.AuthService.saveToken(token);
      await auth_service.AuthService.saveUserDetails(userId, username);

      if (mounted) {
        showAnimatedSnackBar(
          context,
          "Sign Up Sucessfully",
          isSuccess: true,
          isTop: true,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BottomNavBar(currentIndex: 0),
          ),
        );
      }
    } else {
      showAnimatedSnackBar(
        context,
        "Invalid credentials",
        isError: true,
        isTop: true,
      );
    }

    setState(() {
      _isLoading = false;
    });
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
              child: Icon(
                Icons.person_add_alt_1,
                size: 65,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            MyLabel(
              text: "Register",
              color: Theme.of(context).colorScheme.primary,
              size: 80,
              isTitle: true,
            ),
            MyTextField(
              controller: _usernameController,
              hintext: "Enter your username",
              obscuretext: false,
              width: 80,
              height: 20,
              maxlines: 1,
              prefixicon: Icon(Icons.person),
            ),
            MyTextField(
              controller: _emailController,
              hintext: "Enter your email",
              obscuretext: false,
              width: 80,
              height: 20,
              maxlines: 1,
              prefixicon: Icon(Icons.alternate_email),
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
            MyTextField(
              controller: _passwordConfirmController,
              hintext: "Enter your password again!",
              obscuretext: true,
              width: 80,
              height: 20,
              maxlines: 1,
              prefixicon: Icon(Icons.lock),
            ),
            _isLoading
                ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: const CircularProgressIndicator()),
                )
                : MyButton(onPressed: () {}, text: "Register"),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(createRoute(const LoginPage()));
              },
              child: Container(
                margin: EdgeInsets.only(left: 120),
                child: MyLabel(
                  text: "Already have a Account? Login",
                  size: 15,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
