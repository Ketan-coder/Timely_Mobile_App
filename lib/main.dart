import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/components/bottom_nav_bar.dart';
import 'screens/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAuthenticated = prefs.getString('auth_token') != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth Demo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: Colors.deepPurple,
        primaryColorDark: Colors.deepPurple[800],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple[100],
          secondary: Colors.deepPurple[300],
          onError: Colors.red[800],
          errorContainer: Colors.red[100],
          tertiary: Colors.deepPurple[100],
          surface: Colors.black87,
          inverseSurface: Colors.white,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'Poppins',
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Poppins',
          ),
          bodySmall: TextStyle(
            fontFamily: 'Poppins',
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple[100],
          secondary: Colors.deepPurple[800],
          onError: Colors.red[800],
          errorContainer: Colors.red[100],
          tertiary: Colors.deepPurple[100],
          surface: Colors.white,
          inverseSurface: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: _isAuthenticated
          ? const BottomNavBar(currentIndex: 0)
          : const LoginPage(),
    );
  }
}
