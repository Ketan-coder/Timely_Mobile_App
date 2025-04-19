import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_service.dart' as auth_service;
import '../auth/user_details_service.dart';
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
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordConfirmController =
  TextEditingController();
  bool _isLoading = false;

  // Not completed, because API isn't Build for this!
  Future<void> _signUp() async {
    if (_usernameController.text
        .trim()
        .isEmpty) {
      showAnimatedSnackBar(
        context,
        "Username cannot be empty",
        isError: true,
        isTop: true,
      );
      return;
    } else if (_passwordController.text
        .trim()
        .isEmpty ||
        _passwordConfirmController.text
            .trim()
            .isEmpty) {
      showAnimatedSnackBar(
        context,
        "Password Fields cannot be empty",
        isError: true,
        isTop: true,
      );
      return;
    } else if (_firstNameController.text
        .trim()
        .isEmpty ||
        _lastNameController.text
            .trim()
            .isEmpty) {
      showAnimatedSnackBar(
        context,
        "Named Field cannot be empty",
        isError: true,
        isTop: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api-auth/v1/api-register/',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'username': _usernameController.text,
        'password': _passwordController.text,
        'password2': _passwordConfirmController.text,
      }),
    );

    if (response.statusCode == 201) {
      FocusScope.of(context).unfocus();
      final Map<String, dynamic> data = jsonDecode(response.body);

      final String? token = data['token'];
      final int? userId = data['user']['id'];
      final String? username = data['user']['username'];
      final String? email = data['user']['email'];
      final String? firstName = data['user']['first_name'];
      final String? lastName = data['user']['last_name'];

      if (token == null ||
          userId == null ||
          username == null ||
          email == null ||
          firstName == null ||
          lastName == null) {
        throw Exception(
          "Invalid response from server. Missing required fields.",
        );
      }

      print("Token: $token");
      print("User ID: $userId");
      print("username: $username");

      await auth_service.AuthService.saveToken(token);
      await auth_service.AuthService.saveUserDetails(userId, username);

      await UserStorageHelper.saveUserDetailsAll(userId: userId,
          username: username,
          email: email,
          firstName: firstName,
          lastName: lastName);

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
      final Map<String, dynamic> data = jsonDecode(response.body);
      final dynamic errorMessage = data['error'] ??
          data['non_field_errors'] ??
          data['username'] ??
          data['email'] ??
          data['password'] ??
          data['password2'] ??
          'An unknown error occurred.';

      if (errorMessage is List) {
        for (var error in errorMessage) {
          showAnimatedSnackBar(
        context,
        error.toString(),
        isError: true,
        isTop: true,
          );
          await Future.delayed(const Duration(seconds: 2)); // Delay for each error
        }
      } else if (errorMessage is String) {
        showAnimatedSnackBar(
          context,
          errorMessage,
          isError: true,
          isTop: true,
        );
      } else {
        showAnimatedSnackBar(
          context,
          'An unknown error occurred.',
          isError: true,
          isTop: true,
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        physics: PageScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 180),
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: Icon(
                  Icons.person_add_alt_1,
                  size: 65,
                  color: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                ),
              ),
              MyLabel(
                text: "Register",
                color: Theme
                    .of(context)
                    .colorScheme
                    .primary,
                size: 80,
                isTitle: true,
              ),
              Row(
                children: [
                  Expanded(
                    child: MyTextField(
                      controller: _firstNameController,
                      hintext: 'Enter First Name',
                      obscuretext: false,
                      width: 50,
                      height: 20,
                      maxlines: 1,
                      prefixicon: Icon(Icons.edit),
                    ),
                  ),
                  Expanded(
                    child: MyTextField(
                      controller: _lastNameController,
                      hintext: 'Enter Last Name',
                      obscuretext: false,
                      width: 50,
                      height: 20,
                      maxlines: 1,
                      prefixicon: Icon(Icons.edit),
                    ),
                  ),
                ],
              ),
              MyTextField(
                controller: _usernameController,
                hintext: "Enter your username",
                obscuretext: false,
                width: 80,
                height: 20,
                maxlines: 1,
                prefixicon: Icon(Icons.alternate_email),
              ),
              MyTextField(
                controller: _emailController,
                hintext: "Enter your email",
                obscuretext: false,
                width: 80,
                height: 20,
                maxlines: 1,
                prefixicon: Icon(Icons.email),
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
                  : MyButton(onPressed: () => _signUp(), text: "Register"),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(createRoute(const LoginPage()));
                },
                child: Container(
                  margin: EdgeInsets.only(left: 120),
                  child: MyLabel(
                    text: "Already have a Account? Login",
                    size: 15,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
