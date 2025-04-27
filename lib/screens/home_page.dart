import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animated_icons/icons8.dart';
import 'package:http/http.dart' as http;
import 'package:timely/components/button.dart';
import 'package:timely/components/custom_loading_animation.dart';
import 'package:timely/screens/add_notebook.dart';
import 'package:timely/screens/notebook_detail_page.dart';
import '../auth/auth_service.dart' as auth_service;
import '../components/bottom_nav_bar.dart';
import '../components/custom_page_animation.dart';
import '../components/custom_snack_bar.dart';
import '../components/text_field.dart';
import '../models/notebook.dart';
import '../utils/date_formatter.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'package:flutter_slidable/flutter_slidable.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _notebooks = [];
  final double _titleOpacity = 1.0; // Controls title visibility
  bool _isRefreshing = false;
  String? _token; // Store token
  //Timer? _updateTimer;
  List<Notebook> _filteredNotebooks = [];
  late AnimationController _bookController;


  @override
  void initState() {
    super.initState();
    _initializeData();
    _bookController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..repeat();
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
    _bookController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    _token = await auth_service.AuthService.getToken();
    if (_token != null) {
      setState(() => _isRefreshing = true);
      await auth_service.AuthService.fetchNotebooks(_token!);
      await _loadNotebooks();
      setState(() => _isRefreshing = false);
      _filteredNotebooks =
          _notebooks.map((map) => Notebook.fromJson(map)).toList();
      _filterWith = 'all';
      _filterNotebooks();
    } else {
      showAnimatedSnackBar(
          context, 'You are not Authenticated! Please Login!', isError: true);
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
      showAnimatedSnackBar(context, 'Something Went Wrong: $e', isError: true);
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


  bool _checkPassword(String inputedPassword, String realPasswordHash) {
    // Hash the entered password
    // var bytes = utf8.encode(inputedPassword);
    // var hashedPassword = sha256.convert(bytes).toString();

    // Compare with the real hash
    return inputedPassword == realPasswordHash;
  }

  Future<void> _showPasswordInputDialog(BuildContext context, int notebookID, String notebookName, String realPasswordHash, bool isPasswordProtected) async {
    if (!isPasswordProtected) {
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
                  child: const Text(
                      "Proceed", style: TextStyle(color: Colors.green)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Notebook> _searchedNotebooks = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String? _filterWith;

  void _filterNotebooks() {
    setState(() {
      if (_filterWith == 'lockedNotebooks') {
        _filteredNotebooks = _notebooks
            .map((map) => Notebook.fromJson(map))
            .where((notebook) => notebook.isPasswordProtected == true)
            .toList();
      } else if (_filterWith == 'favouriteNotebooks') {
        // Assuming you have an 'isFavourite' property in your Notebook model
        _filteredNotebooks = _notebooks
            .map((map) => Notebook.fromJson(map))
            .where((notebook) => notebook.isFavourite == true)
            .toList();
      } else if (_filterWith == 'high') {
        // Assuming you have a 'priority' property in your Notebook model (e.g., 'high', 'medium', 'low')
        _filteredNotebooks = _notebooks
            .map((map) => Notebook.fromJson(map))
            .where((notebook) =>
        notebook.priority == 0 || notebook.priority == 1)
            .toList();
      } else if (_filterWith == 'low') {
        _filteredNotebooks = _notebooks
            .map((map) => Notebook.fromJson(map))
            .where((notebook) =>
        notebook.priority == 4 || notebook.priority == 5)
            .toList();
      } else if (_filterWith == 'isShared') {
        _filteredNotebooks =
            _notebooks.map((map) => Notebook.fromJson(map)).where((
                notebook) => notebook.isShared == true).toList();
      } else if (_filterWith == 'all' || _filterWith == null) {
        // If no filter is selected or an invalid filter, show all notebooks
        _filteredNotebooks =
            _notebooks.map((map) => Notebook.fromJson(map)).toList();
      } else {
        // If no filter is selected or an invalid filter, show all notebooks
        _filteredNotebooks =
            _notebooks.map((map) => Notebook.fromJson(map)).toList();
      }
    });
  }

  Future<void> toggleIsPublic(int notebookID, bool currentStatus) async {
    // If making it public, ask for confirmation
    if (!currentStatus) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          title: const Text("Make Public?"),
          content: const Text(
            "Are you sure you want to make this notebook public?\n\n"
            "Anyone on the platform will be able to access it.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                  Theme.of(context).colorScheme.errorContainer,
                ),
                foregroundColor: WidgetStateProperty.all<Color>(
                  Theme.of(context).colorScheme.error,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Yes, Make Public"),
            ),
          ],
        ),
      );

      if (confirm != true) return; // User cancelled
    }

    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/notebooks/$notebookID/',
    );

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $_token',
      },
      body: jsonEncode({'is_public': !currentStatus}),
    );

    if (response.statusCode == 200) {
      showAnimatedSnackBar(
        context,
        !currentStatus
            ? "This notebook is now public. Anyone on the platform can access it!"
            : "This notebook is now private. Only you can access it.",
        isSuccess: true,
        isTop: true,
      );

      setState(() {
        _notebooks = _notebooks.map((notebook) {
          if (notebook['id'] == notebookID) {
            notebook['is_public'] = !currentStatus;
          }
          return notebook;
        }).toList();
      });

      _initializeData();
    } else {
      showAnimatedSnackBar(
        context,
        "Failed to update visibility. Please try again.",
        isError: true,
        isTop: true,
      );
    }
  }



  @override
  Widget build(BuildContext context) {

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
              Navigator.of(context).push(
                createRoute(AddNotebookPage())
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
              SliverToBoxAdapter( // Added SliverToBoxAdapter for the search bar
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 5.0),
                  child: MyTextField(
                    controller: _searchController,
                    height: 18,
                    hintTexts: const [
                      'Search notebooks',
                      'Search Description',
                      'Search pages and Subpages'
                    ],
                    // Provide a list of hints
                    hintext: 'Search',
                    obscuretext: false,
                    maxlines: 1,
                    prefixicon: const Icon(Icons.search),
                    width: 80,
                    onChanged: (searchText) async {
                      setState(() {
                        _isSearching = searchText.isNotEmpty;
                        _searchedNotebooks = []; // Clear previous results
                      });
                      if (searchText.isNotEmpty) {
                        List<Notebook> results = await auth_service.AuthService
                            .searchNotebooks(_token!, searchText);
                        setState(() {
                          _searchedNotebooks = results;
                        });
                        //print('Search results: ${_searchedNotebooks.length}');
                      } else {
                        //print('Search text is empty');
                        setState(() {
                          _searchedNotebooks = [];
                          _isSearching = false;
                        });
                      }
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 2.0),
                      padding: EdgeInsets.only(left: 15.0),
                      child: Row(
                        children: [
                          MyButton(onPressed: () {
                            setState(() {
                              _filterWith = 'all';
                              _filterNotebooks();
                            });
                          },
                              text: 'All Notebooks',
                              isSmall: true,
                              isGhost: _filterWith != 'all'),
                          MyButton(onPressed: () {
                            setState(() {
                              _filterWith = 'isShared';
                              _filterNotebooks();
                            });
                          },
                              text: 'Notebooks - Shared by you',
                              isSmall: true,
                              isGhost: _filterWith != 'isShared'),
                          MyButton(onPressed: () {
                            Navigator.push(context,
                                createRoute(BottomNavBar(currentIndex: 3)));
                          },
                              text: 'Notebooks - Shared with you',
                              isSmall: true,
                              isGhost: true),
                          MyButton(onPressed: () {
                            setState(() {
                              _filterWith = 'lockedNotebooks';
                              _filterNotebooks();
                            });
                          },
                              text: 'Locked Notebooks',
                              isSmall: true,
                              isGhost: _filterWith != 'lockedNotebooks'),
                          MyButton(onPressed: () {
                            setState(() {
                              _filterWith = 'favouriteNotebooks';
                              _filterNotebooks();
                            });
                          },
                              text: 'Favourite Notebooks',
                              isSmall: true,
                              isGhost: _filterWith != 'favouriteNotebooks'),
                          MyButton(onPressed: () {
                            setState(() {
                              _filterWith = 'high';
                              _filterNotebooks();
                            });
                          },
                              text: 'Highest Priority',
                              isSmall: true,
                              isGhost: _filterWith != 'high'),
                          MyButton(onPressed: () {
                            setState(() {
                              _filterWith = 'low';
                              _filterNotebooks();
                            });
                          },
                              text: 'Lowest Priority',
                              isSmall: true,
                              isGhost: _filterWith != 'low'),
                        ],
                      )
                  ),
                ),
              ),
              if (_isRefreshing)
                SliverToBoxAdapter(
                  child: CustomLoadingElement(bookController: _bookController,backgroundColor: Theme.of(context).colorScheme.primary,)
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final notebook;
                    if (_isSearching) {
                      notebook = _searchedNotebooks[index];
                    } else if (_filterWith != null) {
                      notebook = _filteredNotebooks[index];
                    } else {
                      notebook = Notebook.fromJson(_notebooks[index]);
                    }

                    bool isProtected = notebook.isPasswordProtected ?? false;
                    bool isPublic = notebook.isPublic ?? false;
                    bool isFavourite = notebook.isFavourite ?? false;
                    bool isShared = notebook.isShared ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(top: 8, left: 5, right: 5),
                      child: Slidable(
                        key: ValueKey(notebook.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) => toggleIsPublic(
                                notebook.id,
                                isPublic,
                              ),
                              backgroundColor: Theme.of(context).colorScheme.error,
                              foregroundColor: Theme.of(context).colorScheme.errorContainer,
                              icon: isPublic ? Icons.person : Icons.public,
                              label: isPublic ? 'Private' : 'Public',
                            ),
                            SlidableAction(
                              onPressed: (context) {
                                // Your edit logic here
                              },
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.surface,
                              icon: isShared ? Icons.undo_sharp : Icons.share,
                              label: isShared ? 'Un-Share' : 'Share',
                            ),
                          ],
                        ),
                        child: ListTile(
                          textColor: Theme
                              .of(context)
                              .colorScheme
                              .surface,
                          title: Text(
                            notebook.title ?? 'Untitled',
                            style: TextStyle(
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Sora',
                            ),
                          ),
                          subtitle: Text(
                              formatDateTime((notebook.updatedAt).toString())),
                          leading: Icon(Icons.book,
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .tertiary),
                          trailing: isProtected
                              ? Icon(Icons.lock,
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .primary)
                              : isPublic
                              ? Icon(Icons.public, color: Colors.green)
                              : isFavourite
                              ? Icon(Icons.favorite, color: Colors.red)
                              : isShared
                              ? Icon(Icons.share, color: Colors.blue)
                              : SizedBox(),
                          //isThreeLine: isShared ? true : false,
                          onTap: () async {
                            await _showPasswordInputDialog(
                              context,
                              notebook.id,
                              notebook.title,
                              notebook.password.toString(),
                              isProtected,
                            );
                          },
                        ),
                      ),
                    );
                  },
                  childCount: _isSearching
                      ? _searchedNotebooks.length
                      : _filterWith != null
                          ? _filteredNotebooks.length
                          : _notebooks.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
