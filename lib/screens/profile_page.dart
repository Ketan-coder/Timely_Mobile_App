import 'package:flutter/material.dart';
import 'package:flutter_animated_icons/icons8.dart';
import 'package:timely/auth/auth_service.dart' as auth_service;
import 'package:timely/components/button.dart';
import 'package:timely/components/custom_loading_animation.dart';
import 'package:timely/screens/login_screen.dart';
import 'package:timely/services/internet_checker_service.dart';

import '../auth/user_details_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  String? _token; // Store token
  bool isAuthenticated = false;
  late InternetChecker _internetChecker;

  Map<String, dynamic> _userDetails = {};
  late AnimationController _bookController;

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
    setState(() {
      _isRefreshing = true;
    });
    isAuthenticated = await UserStorageHelper.isLoggedIn();
    if (isAuthenticated && mounted) {
      final details = await UserStorageHelper.getUserDetails();
      setState(() {
        _userDetails = details!;
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
                    // Expanded(child:SizedBox(height: 100,)),
                    MyButton(onPressed: () => _logout(context), text: 'Logout', isGhost: true)
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
