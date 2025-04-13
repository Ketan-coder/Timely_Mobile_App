import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timely/screens/add_notebook.dart';
import 'package:timely/screens/notebook_detail_page.dart';
import '../auth/auth_service.dart' as auth_service;
import '../components/custom_page_animation.dart';
import '../components/custom_snack_bar.dart';
import '../models/notebook.dart';
import 'login_screen.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _notebooks = [];
  final double _titleOpacity = 1.0; // Controls title visibility
  bool _isRefreshing = false;
  String? _token; // Store token
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _initializeData();
    // _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
    //   if (_token != null) {
    //     print("Here");
    //     _initializeData();
    //   }
    // });
  }

  @override
  void dispose() {
    // _updateTimer?.cancel(); // Stop the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _initializeData() async {
    _token = await auth_service.AuthService.getToken();
    if (_token != null) {
      setState(() => _isRefreshing = true);
      await auth_service.AuthService.fetchNotebooks(_token!);
      await _loadNotebooks();
      setState(() => _isRefreshing = false);
    } else {
      print("Error: Authentication token is null");
    }
    return;
  }

  Future<void> _loadNotebooks() async {
    try {
      List<Notebook> notebooks =
      await auth_service.AuthService.loadNotebooksFromLocal();

      setState(() {
        _notebooks = notebooks.map((notebook) => notebook.toJson()).toList();
      });
    } catch (e) {
      print("Error loading notebooks: $e");
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

  String _formatDateTime(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      String formattedDate = DateFormat("hh:mm a d'th' MMMM, yyyy").format(dateTime);
      return formattedDate;
    } catch (e) {
      return "Invalid date";
    }
  }

  bool _checkPassword(String inputedPassword, String realPasswordHash) {
    // Hash the entered password
    // var bytes = utf8.encode(inputedPassword);
    // var hashedPassword = sha256.convert(bytes).toString();

    // Compare with the real hash
    return inputedPassword == realPasswordHash;
  }

  Future<void> _showPasswordInputDialog(BuildContext context, int notebookID, String notebookName, String realPasswordHash, bool isPasswordProtected) async {
    if (!isPasswordProtected) {
      //Navigator.push(
      //  context,
      //  MaterialPageRoute(builder: (context) => NotebookDetailPage(notebookId: notebookID)),
      //);
      Navigator.of(context).push(createRoute(NotebookDetailPage(
          notebookId: notebookID, isPasswordProtected: isPasswordProtected)));
      return; // Stop execution, no need to show password dialog
    }

    TextEditingController passwordController = TextEditingController();
    bool isWrongPassword = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent closing when tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.inverseSurface,
              title: const Text("Enter Password"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Enter the password to access '$notebookName'."),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true, // Hide password input
                    decoration: InputDecoration(
                      labelText: "Password",
                      errorText: isWrongPassword ? "Incorrect password" : null,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // ❌ Cancel
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    String inputPassword = passwordController.text.trim();

                    if (_checkPassword(inputPassword, realPasswordHash)) {
                      Navigator.of(context).pop(); // ✅ Close dialog
                      showAnimatedSnackBar(
                          context, "Correct Password", isSuccess: true,
                          isTop: true);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NotebookDetailPage(notebookId: notebookID),
                        ),
                      );
                    } else {
                      // ❌ Wrong password, show error
                      setState(() {
                        isWrongPassword = true;
                      });
                      showAnimatedSnackBar(
                          context, "Wrong Password! Please Try Again.",
                          isError: true, isTop: true);
                    }
                  },
                  child: const Text("Proceed", style: TextStyle(color: Colors.green)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDarkMode = brightness == Brightness.dark;
    print("Is Dark Mode: $isDarkMode");
    final imageUrl = !isDarkMode
        ? "https://th.bing.com/th/id/OIP.YRIUUjhcIMvBEf_bbOdpUwHaEU?rs=1&pid=ImgDetMain"
        : "https://c8.alamy.com/comp/2E064N7/plain-white-background-or-wallpaper-abstract-image-2E064N7.jpg";

    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .inverseSurface,
      // floatingActionButton: IconButton(onPressed: () async { await _initializeData();}, icon: Icon(Icons.refresh)),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the right
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FloatingActionButton(
              heroTag: 'Refresh Notebooks',
              backgroundColor: Theme
                  .of(context)
                  .colorScheme
                  .inverseSurface,
              foregroundColor: Theme
                  .of(context)
                  .colorScheme
                  .surface,
              tooltip: "Refresh Notebooks",
              onPressed: () async {
                await _initializeData();
              },
              child: Icon(Icons.refresh),
            ),
          ),
          SizedBox(width: 12), // Adds spacing between buttons
          FloatingActionButton(
            heroTag: 'Add Notebook Button',
            tooltip: "Add Notebook",
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AddNotebookPage(),
                ),
              );
            },
            child: Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_token != null) {
            _initializeData(); // ✅ Pull-to-refresh now fetches API data
          }
        },
        child: NotificationListener<ScrollNotification>(
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
                actions: [
                  IconButton(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primary,
                  ),
                ],
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
                        opacity: _titleOpacity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //Padding(
                            //  padding: const EdgeInsets.only(left: 1.0),
                            //  child: Icon(Icons.book,size: 40,color: Theme.of(context).colorScheme.primary),
                            // ),
                            Text(
                              "Notebooks",
                              style: TextStyle(
                                color: Theme
                                    .of(context)
                                    .colorScheme
                                    .primary ?? Colors.white,
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
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final notebook = _notebooks[index];
                        bool isProtected = notebook['is_password_protected'] ??
                            false;
                        return Padding(
                          padding: const EdgeInsets.only(
                              top: 8, left: 5, right: 5),
                          child: ListTile(
                            textColor: Theme
                                .of(context)
                                .colorScheme
                                .surface,
                            title: Text(notebook['title'] ?? 'Untitled',
                              style: TextStyle(color: Theme
                                  .of(context)
                                  .colorScheme
                                  .primary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Sora'),),
                            subtitle: Text(
                                '${_formatDateTime(notebook['updated_at'])}'),
                            leading: Icon(Icons.book, color: Theme
                                .of(context)
                                .colorScheme
                                .tertiary,),
                            trailing: isProtected
                                ? const Icon(Icons.lock, color: Colors.red)
                                : const SizedBox(),
                            onTap: () async {
                              await _showPasswordInputDialog(
                                  context, notebook['id'], notebook['title'],
                                  notebook['password'].toString(), isProtected);
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => NotebookDetailPage(
                              //       notebookId: notebook['id'],
                              //       isPasswordProtected: isProtected,
                              //     ),
                              //   ),
                              // );
                            },
                          ),
                        );
                  },
                  childCount: _notebooks.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
