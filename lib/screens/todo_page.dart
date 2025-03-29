import 'package:flutter/material.dart';
import 'package:timely/auth/auth_service.dart' as auth_service;
import 'package:timely/models/todo.dart';
import 'package:timely/screens/login_screen.dart';
import 'package:intl/intl.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<Map<String, dynamic>> _todos = [];
  final double _titleOpacity = 1.0; // Controls title visibility
  bool _isRefreshing = false;
  String? _token;
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
      await auth_service.AuthService.fetchTodos(_token!);
      await _loadTodos();
      setState(() => _isRefreshing = false);
    } else {
      print("Error: Authentication token is null");
    }
    return;
  }

  Future<void> _loadTodos() async {
    try {
      List<Todo> todos =
      await auth_service.AuthService.loadTodoFromLocal();

      setState(() {
        _todos = todos.map((todos) => todos.toJson()).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the right
        children: [
          Padding(
            padding: const EdgeInsets.only(right:8.0),
            child: FloatingActionButton(
              heroTag: 'Refresh Notebooks',
              backgroundColor: Theme.of(context).colorScheme.inverseSurface,
              foregroundColor: Theme.of(context).colorScheme.surface,
              tooltip: "Refresh Notebooks",
              onPressed: () { },
              child: Icon(Icons.refresh),
            ),
          ),
          SizedBox(width: 12), // Adds spacing between buttons
          FloatingActionButton(
            heroTag: 'Add Notebook Button',
            tooltip: "Add Notebook",
            onPressed: () {
              
            },
            child: Icon(Icons.add),
          ),
        ],
      ),
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
                  toolbarHeight: 60.0,
                  actions: [
                    IconButton(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                  flexibleSpace: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          "https://th.bing.com/th/id/OIP.YRIUUjhcIMvBEf_bbOdpUwHaEU?rs=1&pid=ImgDetMain",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey,
                              child: const Center(
                                child: Text("Image failed to load"),
                              ),
                            );
                          },
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
                                "Todos",
                                style: TextStyle(
                                  color: Theme
                                      .of(context)
                                      .colorScheme
                                      .tertiary ?? Colors.white,
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
                      final notebook = _todos[index];
                      bool isCompleted = notebook['is_completed'] ?? false;
                      return ListTile(
                        textColor: Theme.of(context).colorScheme.surface,
                        title: Text(notebook['title'] ?? 'Untitled',style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18,fontWeight: FontWeight.w800,fontFamily: 'Sora'),),
                        subtitle: Text('Last updated: ${_formatDateTime(notebook['updated_at'])}'),
                        leading: isCompleted
                            ? const Icon(Icons.done, color: Colors.green)
                            : const SizedBox(),
                        onTap: () async {
                          // await _showPasswordInputDialog(context,notebook['id'],notebook['title'],notebook['password'].toString(),isProtected);
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
                      );
                    },
                    childCount: _todos.length,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
