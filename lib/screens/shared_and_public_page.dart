import 'package:flutter/material.dart';
import 'package:flutter_animated_icons/icons8.dart';
import 'package:intl/intl.dart';
import 'package:timely/components/custom_loading_animation.dart';

import '../auth/auth_service.dart' as auth_service;
import '../components/custom_page_animation.dart';
import '../components/text_field.dart';
import '../models/notebook.dart';
import 'login_screen.dart';
import 'notebook_detail_page.dart';

class SharedAndPublicPage extends StatefulWidget {
  const SharedAndPublicPage({super.key});

  @override
  State<SharedAndPublicPage> createState() => _SharedAndPublicPageState();
}

class _SharedAndPublicPageState extends State<SharedAndPublicPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  List<Map<String, dynamic>> _sharedNotebooks = [];
  List<Map<String, dynamic>> _publicNotebooks = [];
  final double _titleOpacity = 1.0; // Controls title visibility
  String? _token; // Store token

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    _token = await auth_service.AuthService.getToken();
    if (_token != null) {
      setState(() => _isRefreshing = true);
      await auth_service.AuthService.fetchSharedNotebooks(_token!);
      await auth_service.AuthService.fetchPublicNotebooks(_token!);
      await _loadSharedNotebooks();
      setState(() => _isRefreshing = false);
    } else {
      print("Error: Authentication token is null");
    }
    return;
  }

  Future<void> _loadSharedNotebooks() async {
    try {
      List<Notebook> sharedNotebooks =
      await auth_service.AuthService.loadSharedNotebooksFromLocal();
      List<Notebook> publicNotebooks =
      await auth_service.AuthService.loadPublicNotebooksFromLocal();

      setState(() {
        _sharedNotebooks =
            sharedNotebooks.map((notebook) => notebook.toJson()).toList();
        _publicNotebooks =
            publicNotebooks.map((notebook) => notebook.toJson()).toList();
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
      String formattedDate = DateFormat("hh:mm a d'th' MMMM, yyyy").format(
          dateTime);
      return formattedDate;
    } catch (e) {
      return "Invalid date";
    }
  }

  //@override
  //void initState() {
  //  super.initState();
  //  _tabController = TabController(length: 2, vsync: this);
  //}

  //@override
  //void dispose() {
  //  _tabController.dispose();
  //  super.dispose();
  //}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              SharedTab(sharedNotebooks: _sharedNotebooks,
                  isRefreshing: _isRefreshing, token: _token),
              PublicTab(publicNotebooks: _publicNotebooks,
                  isRefreshing: _isRefreshing, token: _token)
            ],
          ),
          //if (_isRefreshing) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: IconButton(
        onPressed: () => _initializeData(),
        icon: Icon(Icons.refresh),
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.inverseSurface,
        child: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.surface,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 2,
          dividerColor: Colors.transparent,
          indicatorAnimation: TabIndicatorAnimation.elastic,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 15),
                    Text(
                      "Shared",
                      style: TextStyle(fontSize: 20, fontFamily: 'Sora'),
                    ),
                  ],
                ),
              ),
            ),
            Tab(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.public),
                    SizedBox(width: 15),
                    Text(
                      "Public",
                      style: TextStyle(fontSize: 20, fontFamily: 'Sora'),
                    ),
                  ],
                ),
              ),
            ),
            //Tab(icon: Icon(Icons.public), text: "Public"),
          ],
        ),
      ),
    );
  }
}

class SharedTab extends StatefulWidget {
  final List<Map<String, dynamic>> sharedNotebooks;
  final bool isRefreshing;
  String? token;

  //SharedTab({super.key, required this.sharedNotebooks});
  SharedTab(
      {Key? key, required this.sharedNotebooks, required this.isRefreshing, required this.token})
      : super(key: key);

  @override
  State<SharedTab> createState() => _SharedTabState();
}

class _SharedTabState extends State<SharedTab> with SingleTickerProviderStateMixin {
  final TextEditingController _searchSharedNotebook = TextEditingController();
  List<Notebook> _searchedSharedNotebooks = [];
  bool _isSearching = false;
  late AnimationController _bookController;

  @override
  void initState() {
    super.initState();
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

  String _formatDateTime(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      String formattedDate = DateFormat("hh:mm a d'th' MMMM, yyyy").format(
          dateTime);
      return formattedDate;
    } catch (e) {
      return "Invalid date";
    }
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
                            "Shared\nNotebooks",
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
            SliverToBoxAdapter( // Added SliverToBoxAdapter for the search bar
              child: Container(
                margin: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 5.0),
                child: MyTextField(
                  controller: _searchSharedNotebook,
                  height: 18,
                  hintTexts: const [
                    'Search Shared notebooks',
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
                      _searchedSharedNotebooks = []; // Clear previous results
                    });
                    if (searchText.isNotEmpty) {
                      List<Notebook> results = await auth_service.AuthService
                          .searchSharedNotebooks(widget.token!, searchText);
                      setState(() {
                        _searchedSharedNotebooks = results;
                      });
                      print(
                          'Search results: ${_searchedSharedNotebooks.length}');
                    } else {
                      print('Search text is empty');
                      setState(() {
                        _searchedSharedNotebooks = [];
                        _isSearching = false;
                      });
                    }
                  },
                ),
              ),
            ),
            if (widget.isRefreshing)
              SliverToBoxAdapter(
                  child: CustomLoadingElement(bookController: _bookController,backgroundColor: Theme.of(context).colorScheme.primary)
                ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  //final notebook = widget.sharedNotebooks[index];
                  final notebook;
                  if (_isSearching) {
                    notebook = _searchedSharedNotebooks[index];
                  } else {
                    notebook = Notebook.fromJson(widget.sharedNotebooks[index]);
                  }
                  bool isProtected = notebook.isPasswordProtected ??
                      false;
                  return Padding(
                    padding: const EdgeInsets.only(
                        top: 10, left: 5, right: 5),
                    child: ListTile(
                      textColor: Theme
                          .of(context)
                          .colorScheme
                          .surface,
                      title: Text(notebook.title ?? 'Untitled',
                        style: TextStyle(color: Theme
                            .of(context)
                            .colorScheme
                            .primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Sora'),),
                      subtitle: Text(
                          '${_formatDateTime((notebook.updatedAt)
                              .toString())}'),
                      leading: Icon(Icons.book, color: Theme
                          .of(context)
                          .colorScheme
                          .tertiary,),
                      trailing: isProtected
                          ? const Icon(Icons.lock, color: Colors.red)
                          : const SizedBox(),
                      onTap: () async {
                        //await _showPasswordInputDialog(
                        //    context, notebook['id'], notebook['title'],
                        //    notebook['password'].toString(), isProtected);
                        Navigator.of(context).push(createRoute(
                            NotebookDetailPage(
                                notebookId: notebook.id,
                                isPasswordProtected: isProtected)));
                      },
                    ),
                  );
                },
                childCount: _isSearching
                    ? _searchedSharedNotebooks.length
                    : widget.sharedNotebooks.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PublicTab extends StatefulWidget {
  List<Map<String, dynamic>> publicNotebooks;
  final bool isRefreshing;
  String? token;

  PublicTab(
      {super.key, required this.publicNotebooks, required this.isRefreshing, required this.token});

  @override
  State<PublicTab> createState() => _PublicTabState();
}

class _PublicTabState extends State<PublicTab> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Notebook> _searchedNotebooks = [];
  bool _isSearching = false;
  late AnimationController _publicController;
  @override
  void initState() {
    super.initState();
    _publicController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    _publicController.dispose();
    super.dispose();
  }

  String _formatDateTime(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      String formattedDate = DateFormat("hh:mm a d'th' MMMM, yyyy").format(
          dateTime);
      return formattedDate;
    } catch (e) {
      return "Invalid date";
    }
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
                            "Public\nNotebooks",
                            style: TextStyle(
                              color:
                              Theme
                                  .of(context)
                                  .colorScheme
                                  .primary ??
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
            SliverToBoxAdapter( // Added SliverToBoxAdapter for the search bar
              child: Container(
                margin: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 5.0),
                child: MyTextField(
                  controller: _searchController,
                  height: 18,
                  hintTexts: const [
                    'Search Public notebooks',
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
                          .searchPublicNotebooks(widget.token!, searchText);
                      setState(() {
                        _searchedNotebooks = results;
                      });
                      print('Search results: ${_searchedNotebooks.length}');
                    } else {
                      print('Search text is empty');
                      setState(() {
                        _searchedNotebooks = [];
                        _isSearching = false;
                      });
                    }
                  },
                ),
              ),
            ),
            if (widget.isRefreshing)
              SliverToBoxAdapter(
                  child: CustomLoadingElement(bookController: _publicController,backgroundColor: Theme.of(context).colorScheme.primary,icon: Icons8.internet,)
                ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final notebook;
                  if (_isSearching) {
                    notebook = _searchedNotebooks[index];
                  } else {
                    //notebook = widget.publicNotebooks[index];
                    notebook = Notebook.fromJson(widget.publicNotebooks[index]);
                  }
                  print('Notebook Data ==> $notebook');
                  //bool isProtected = notebook['is_password_protected'] ?? false;
                  bool isProtected = notebook.isPasswordProtected ?? false;
                  return Padding(
                    padding: const EdgeInsets.only(
                        top: 10, left: 5, right: 5),
                    child: ListTile(
                      textColor: Theme
                          .of(context)
                          .colorScheme
                          .surface,
                      title: Text(notebook.title ?? 'Untitled',
                        style: TextStyle(color: Theme
                            .of(context)
                            .colorScheme
                            .primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Sora'),),
                      subtitle: Text(
                          '${_formatDateTime((notebook.updatedAt)
                              .toString())}'),
                      leading: Icon(Icons.book, color: Theme
                          .of(context)
                          .colorScheme
                          .tertiary,),
                      trailing: isProtected
                          ? const Icon(Icons.lock, color: Colors.red)
                          : const SizedBox(),
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NotebookDetailPage(
                                  notebookId: notebook.id,
                                  isPasswordProtected: isProtected,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: _isSearching ? _searchedNotebooks.length : widget
                    .publicNotebooks.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
