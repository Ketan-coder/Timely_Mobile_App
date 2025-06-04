import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/components/bottom_nav_bar.dart';
import 'package:timely/services/notification_service.dart';
import 'components/custom_page_animation.dart';
import 'screens/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: ".env");
  await NotificationService.initialize();
  NotificationService.startManualNotificationMonitor();
  // 🔥 Test notification immediately
  // await NotificationService.testImmediateNotification();
  // debugPrint('🔥 Test notification scheduling..........');
  // await NotificationService.scheduleUsingShow(
  //   id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  //   title: '🔥 Emulator Notification',
  //   body: 'You should see this in 20 seconds!',
  //   scheduledDate: DateTime.now().add(Duration(seconds: 20)),
  // );
  // NotificationService.addManualNotification(
  //   id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  //   title: '🔔 Reminder',
  //   body: 'This is a manually checked notification!',
  //   scheduledDate: DateTime.now().add(Duration(seconds: 10)),
  //   channelId: 'manual_notifications',
  //   channelName: 'Manual Notifications',
  //   channelDescription: 'Notifications that are manually tracked',
  // );
  // debugPrint('🔥 Test notification scheduled!');
  

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

  // Custom transition (left-to-right, slow like iOS)
  Route createRoute(Widget secondScreen) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600), // Slow transition
      pageBuilder: (context, animation, secondaryAnimation) => secondScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0); // Start from the left
        const end = Offset.zero; // End at the center
        const curve = Curves.easeInOut; // Smooth slow effect

        var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth Demo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: Colors.deepPurple,
        primaryColorDark: Colors.deepPurple[800],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple[300],
          secondary: Colors.deepPurple[200],
          onError: Colors.red[800],
          errorContainer: Colors.red[100],
          tertiary: Colors.deepPurple[100],
          surface: Colors.black87,
          inverseSurface: Colors.white,
          onPrimary: Colors.deepPurple[50],
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark()
          .copyWith( // Start with Material's well-defined dark theme
        scaffoldBackgroundColor: Colors.black,
        // Or a very dark grey like Colors.grey[900]
        textTheme: ThemeData
            .dark()
            .textTheme
            .copyWith( // Ensure Poppins is applied to dark theme text styles
          bodyMedium: const TextStyle(fontFamily: 'Poppins'),
          bodyLarge: const TextStyle(fontFamily: 'Poppins'),
          bodySmall: const TextStyle(fontFamily: 'Poppins'),
          // You might want to specify other text styles too if needed
        )
            .apply( // Ensures text colors have good contrast on dark backgrounds
          bodyColor: Colors.white, // Example: default body text color
          displayColor: Colors.white70, // Example: default display text color
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          // <<< ESSENTIAL!
          // Let fromSeed generate most colors. Override minimally and carefully.
          // Example overrides (adjust these to your liking):
          primary: Colors.deepPurple[300],
          // A lighter purple can work as primary in dark mode
          onPrimary: Colors.black,
          // Ensure this contrasts well with deepPurple[300]
          secondary: Colors.tealAccent[100],
          // Example of a different accent
          onSecondary: Colors.black,
          surface: Colors.grey[850],
          // Example: if you want a specific dark surface color
          onSurface: Colors.white,
          // Text/icons on surface
          inverseSurface: Colors.black,
          // It's often better to let fromSeed handle these unless you have specific needs:
          // onError: Colors.redAccent[100],
          // errorContainer: Colors.red[800], // Darker container for dark theme
        ),
      ),
      home: _isAuthenticated
          ? const BottomNavBar(currentIndex: 0)
          : const LoginPage(),
    );
  }
}
