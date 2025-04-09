import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timely/auth/auth_service.dart' as auth_service;
import 'package:timely/models/todo.dart';
import 'package:timely/screens/login_screen.dart';
import 'package:intl/intl.dart';

import '../components/custom_snack_bar.dart';

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
      String formattedDate = DateFormat("hh:mm a d'th' MMMM, yyyy").format(
          dateTime);
      return formattedDate;
    } catch (e) {
      return "Invalid date";
    }
  }

  Future<void> _toggleCompleted(int todoId, String todoName,
      bool isCompleted) async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/todos/${todoId}/',
    );
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Token $_token', // Replace with actual token
      },
      body: {
        'is_completed': (!isCompleted).toString(),
      },
    );
    print(response);
    if (response.statusCode == 200) {
      if (isCompleted) {
        _initializeData();
        showAnimatedSnackBar(
            context, "${todoName} has been marked In-Complete Successfully",
            isInfo: true, isTop: true);
      } else {
        _initializeData();
        showAnimatedSnackBar(
            context, "${todoName} has been marked Completed Successfully",
            isSuccess: true, isTop: true);
      }
    } else {
      showAnimatedSnackBar(
          context, "Something went wrong!", isError: true, isTop: true);
    }
  }

  Future<void> _addTodoAPI(String todoName) async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/todos/',
    );
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Token $_token', // Replace with actual token
      },
      body: {
        'title': todoName.trim(),
      },
    );
    print(response);
    if (response.statusCode == 201) {
      _initializeData();
      showAnimatedSnackBar(
          context, "${todoName} Added Successfully", isSuccess: true,
          isTop: true);
    } else {
      showAnimatedSnackBar(
          context, "Something went wrong!", isError: true, isTop: true);
    }
  }

  Future<void> _deleteTodoAPI(int todoId, String todoName) async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/todos/$todoId/',
    );
    final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Token $_token', // Replace with actual token
        }
    );
    print(response);
    if (response.statusCode == 204) {
      _initializeData();
      showAnimatedSnackBar(
          context, "${todoName} Removed!", isSuccess: true,
          isTop: true);
    } else {
      showAnimatedSnackBar(
          context, "Something went wrong!", isError: true, isTop: true);
    }
  }

  Future<void> _addTodo(BuildContext context) async {
    TextEditingController todoController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent closing when tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              //icon: Icon(Icons.add),
              backgroundColor: Theme
                  .of(context)
                  .colorScheme
                  .inverseSurface,
              title: const Text("Add New Todo"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: todoController,
                    decoration: InputDecoration(
                      labelText: "Eg. Call John",
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
                  onPressed: () async {
                    String todo = todoController.text.trim();
                    await _addTodoAPI(todo);
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: const Text(
                      "Add", style: TextStyle(color: Colors.green)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTodo(BuildContext context, int todoID,
      String todoName) async {
    TextEditingController todoController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent closing when tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              //icon: Icon(Icons.add),
              backgroundColor: Theme
                  .of(context)
                  .colorScheme
                  .inverseSurface,
              title: const Text("Delete Todo"),
              content: Text("Are you sure Delete $todoName?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // Cancel
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    await _deleteTodoAPI(todoID, todoName);
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: const Text(
                      "Delete", style: TextStyle(color: Colors.red)),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = isDarkMode
        ? "https://th.bing.com/th/id/OIP.YRIUUjhcIMvBEf_bbOdpUwHaEU?rs=1&pid=ImgDetMain"
        : "https://c8.alamy.com/comp/2E064N7/plain-white-background-or-wallpaper-abstract-image-2E064N7.jpg";

    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .inverseSurface,
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
            onPressed: () => _addTodo(context),
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
                        child: Image.network(
                          imageUrl,
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
                          final todo = _todos[index];
                          bool isCompleted = todo['is_completed'] ?? false;
                          return ListTile(
                            textColor: Theme
                                .of(context)
                                .colorScheme
                                .surface,
                            title: Text(todo['title'] ?? 'Untitled',
                              style: TextStyle(color: Theme
                                  .of(context)
                                  .colorScheme
                                  .primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Sora'),),
                            subtitle: Text('Last updated: ${_formatDateTime(
                                todo['updated_at'])}'),
                            trailing: IconButton(onPressed: () async {
                              await _deleteTodo(
                                  context, todo['id'], todo['title']);
                            }, icon: Icon(Icons.delete, color: Colors.grey,)),
                            leading: isCompleted
                                ? IconButton(
                              icon: Icon(Icons.done, color: Colors.green),
                              onPressed: () async {
                                await _toggleCompleted(todo['id'],
                                    todo['title'], isCompleted);
                              },)
                                : IconButton(icon: Icon(Icons.check_circle),
                              onPressed: () async {
                                await _toggleCompleted(todo['id'],
                                    todo['title'], isCompleted);
                              },),
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
