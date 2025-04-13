import 'package:flutter/material.dart';

import '../auth/user_details_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isRefreshing = false;
  String? _token; // Store token

  Map<String, dynamic> _userDetails = {};

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final details = await UserStorageHelper.getUserDetails();
    setState(() {
      _userDetails = details!;
    });
  }


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = isDarkMode
        ? "https://th.bing.com/th/id/OIP.YRIUUjhcIMvBEf_bbOdpUwHaEU?rs=1&pid=ImgDetMain"
        : "https://c8.alamy.com/comp/2E064N7/plain-white-background-or-wallpaper-abstract-image-2E064N7.jpg";
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
                                  Theme.of(context).colorScheme.primary ??
                                  Colors.white,
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
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Name:',
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
                          const SizedBox(width: 8),
                          Text(
                            '${_userDetails['first_name']} ${_userDetails['last_name']}' ??
                                '',
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
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: ${_userDetails['email']}' ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Sora',
                          color: Theme
                              .of(context)
                              .colorScheme
                              .primary,
                        ),
                      ),
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
