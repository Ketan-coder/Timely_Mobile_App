import 'package:flutter/material.dart';
import 'package:flutter_animated_icons/icons8.dart';
import 'package:timely/auth/api_service.dart';
import 'package:timely/auth/auth_service.dart' as auth_service;
import 'package:timely/components/button.dart';
import 'package:timely/components/custom_loading_animation.dart';
import 'package:timely/models/user_preference.dart';
import 'package:timely/screens/login_screen.dart';
import 'package:timely/services/internet_checker_service.dart';

import '../auth/user_details_service.dart';
import '../components/custom_drop_down.dart';
import '../components/custom_switch_tile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  String? _token; // Store token
  bool isAuthenticated = false;
  late InternetChecker _internetChecker;

  Map<String, dynamic> _userDetails = {};
  late AnimationController _bookController;

  UserPreference? _preferences; 

  List<DropdownMenuItem<String>> themeItems = const [
    DropdownMenuItem(value: "off", child: Text("Off")),
    DropdownMenuItem(value: "auto", child: Text("System")),
    DropdownMenuItem(value: "light", child: Text("Light")),
    DropdownMenuItem(value: "dark", child: Text("Dark")),
  ];

  List<DropdownMenuItem<int>> textSizeItems =  [
    DropdownMenuItem(value: 0, child: Text("Small",style: TextStyle(color: Colors.deepPurple[100]),)),
    DropdownMenuItem(value: 1, child: Text("Medium",style: TextStyle(color: Colors.deepPurple[100]),)),
    DropdownMenuItem(value: 2, child: Text("Large",style: TextStyle(color: Colors.deepPurple[100]),)),
    DropdownMenuItem(value: 3, child: Text("Extra Large",style: TextStyle(color: Colors.deepPurple[100]),)),
  ];

  @override
  void dispose() {
    // _updateTimer?.cancel(); // Stop the timer when the widget is disposed
    _internetChecker.stopMonitoring();
    _bookController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _internetChecker = InternetChecker(context);
    _internetChecker.startMonitoring();
    _loadUserDetails();
    _bookController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..repeat();
  }

  Future<void> _loadUserDetails() async {
    _token = await auth_service.AuthService.getToken();
    setState(() {
      _isRefreshing = true;
      _token = _token;
    });
    isAuthenticated = await UserStorageHelper.isLoggedIn();
    if (isAuthenticated && mounted) {
      final details = await UserStorageHelper.getUserDetails();
      setState(() {
        _userDetails = details!;
        // _isRefreshing = false;
      });
      await ApiService.makeApiCall(
        token: _token!,
        endpoint: '/api-auth/v1/userpreference/',
        internetChecker: _internetChecker,
        method: 'GET',
        onSuccess: (json) async {
          final results = json['results'];
          if (results is List) {
            final prefsModel = UserPreference.fromJson(results.first);
            await auth_service.AuthService.saveUserPreferencesLocally(prefsModel.toJson());
          }
        },
      );
      // final authService = auth_service.AuthService();
      // await authService.fetchUserPreferences(_token!, context);
      final prefs2 = await auth_service.AuthService
          .loadUserPreferencesFromLocal(); // this has the final usable data

      setState(() {
        _preferences = prefs2;
        _isRefreshing = false;
      });

    }
  }

  Future<void> _logout(BuildContext context) async {
    await auth_service.AuthService.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Future<void> _updatePreference(String key, dynamic value,
      int userPerferenceId) async {
    final authService = auth_service.AuthService();

    setState(() {
      if (_preferences == null) return;

      switch (key) {
        case 'notifications_enabled':
          _preferences = _preferences!.copyWith(notifications: value);
          break;
        case 'biometric_enabled':
          _preferences = _preferences!.copyWith(biometric: value);
          break;
        case 'theme':
          _preferences = _preferences!.copyWith(theme: value);
          break;
        case 'text_size':
          _preferences = _preferences!.copyWith(textSize: value);
          break;
      }
    });

    // Optional: Save to server
    await authService.updateUserPreferences(
        _token!, key, value, userPerferenceId, context);

    print("Updated preference: $key = $value");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          // setState(() {
          //   _titleOpacity = (1 - (scrollInfo.metrics.pixels / 100)).clamp(0, 1);
          // });
          return true;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.black,
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              toolbarHeight: 80.0,
              flexibleSpace: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onPrimary,
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Opacity(
                      opacity: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Padding(
                          //  padding: const EdgeInsets.only(left: 1.0),
                          //  child: Icon(Icons.book,size: 40,color: Theme.of(context).colorScheme.primary),
                          // ),
                          Text(
                            "Profile",
                            style: TextStyle(
                              color:
                              Theme
                                  .of(context)
                                  .colorScheme
                                  .primary,
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isRefreshing)
              SliverToBoxAdapter(
                  child: CustomLoadingElement(bookController: _bookController,backgroundColor: Theme.of(context).colorScheme.primary,icon: Icons8.people,)
                ),
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        '${_userDetails['first_name']} ${_userDetails['last_name']}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Sora',
                          color: Theme
                              .of(context)
                              .colorScheme
                              .primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: ${_userDetails['email']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Sora',
                          color: Theme
                              .of(context)
                              .colorScheme
                              .primary,
                        ),
                      ),
                      const Divider(),
                      const Text("Preferences", style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                      CustomSwitchTile(
                        title: "Enable Notifications",
                        value: _preferences?.notificationsEnabled ?? false,
                        onChanged: (val) => _updatePreference(
                            'notifications_enabled', val, _preferences!.id),
                      ),

                      CustomSwitchTile(
                        title: "Enable Biometric",
                        value: _preferences?.biometricEnabled ?? false,
                        onChanged: (value) => _updatePreference(
                            'biometric_enabled', value, _preferences!.id),
                      ),

                      CustomDropdownTile<String>(
                        title: "Theme",
                        value: _preferences?.theme,
                        items: themeItems,
                        onChanged: (val) {
                          if (val != null) _updatePreference(
                              'theme', val, _preferences!.id);
                        },
                      ),

                      CustomDropdownTile<int>(
                        title: "Text Size",
                        value: _preferences?.textSize,
                        items: textSizeItems,
                        onChanged: (val) {
                          if (val != null) _updatePreference(
                              'text_size', val, _preferences!.id);
                        },
                      ),


                      const SizedBox(height: 20),
                      // Expanded(child:SizedBox(height: 100,)),
                      MyButton(onPressed: () => _logout(context),
                          text: 'Logout',
                          isGhost: true)
                    ],
                  ),
                ),
              ]),
            )

          ],
        ),
      ),
    );
  }
}
