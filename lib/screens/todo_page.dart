import 'package:flutter/material.dart';
import 'package:flutter_animated_icons/icons8.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:timely/auth/auth_service.dart' as auth_service;
import 'package:timely/components/custom_loading_animation.dart';
import 'package:timely/models/todo.dart';
import 'package:timely/screens/login_screen.dart';
import 'package:timely/services/internet_checker_service.dart';

import '../components/custom_snack_bar.dart';
import '../utils/date_formatter.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _todos = [];
  final double _titleOpacity = 1.0; // Controls title visibility
  bool _isRefreshing = false;
  String? _token;
  late AnimationController _todoController;
  bool _isCompletedExpanded = false;
  late InternetChecker _internetChecker;

  @override
  void initState() {
    super.initState();
    _internetChecker = InternetChecker(context);
    _internetChecker.startMonitoring();
    _initializeData();
    _todoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )
      ..repeat();
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
    _internetChecker.stopMonitoring();
    _todoController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    _token = await auth_service.AuthService.getToken();
    if (_token != null) {
      setState(() => _isRefreshing = true);
      await auth_service.AuthService.fetchTodos(_token!,_internetChecker);
      await _loadTodos();
      setState(() => _isRefreshing = false);
    } else {
      showAnimatedSnackBar(
          context, "You are not Authenticated, Please Login!", isError: true);
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
      showAnimatedSnackBar(
          context, "Error loading Notebooks: $e", isError: true);
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


  Future<void> _toggleCompleted(int todoId, String todoName,
      bool isCompleted) async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/todos/$todoId/',
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
    //print(response);
    if (response.statusCode == 200) {
      if (isCompleted) {
        _initializeData();
        showAnimatedSnackBar(
            context, "$todoName has been marked In-Complete Successfully",
            isInfo: true, isTop: true);
      } else {
        _initializeData();
        showAnimatedSnackBar(
            context, "$todoName has been marked Completed Successfully",
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
    //print(response);
    if (response.statusCode == 201) {
      _initializeData();
      showAnimatedSnackBar(
          context, "$todoName Added Successfully", isSuccess: true,
          isTop: true);
    } else {
      showAnimatedSnackBar(
          context, "Something went wrong!", isError: true, isTop: true);
    }
  }

  Future<void> _editTodoAPI(int todoId, String updatedTitle) async {
    final url = Uri.parse(
        'https://timely.pythonanywhere.com/api/v1/todos/$todoId/');

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Token $_token',
      },
      body: {
        'title': updatedTitle.trim(),
      },
    );

    if (response.statusCode == 200) {
      _initializeData();
      showAnimatedSnackBar(
        context,
        "Todo updated successfully",
        isSuccess: true,
        isTop: true,
      );
    } else {
      showAnimatedSnackBar(
        context,
        "Failed to update Todo!",
        isError: true,
        isTop: true,
      );
    }
  }

  Future<void> _editTodo(BuildContext context,
      Map<String, dynamic> todoData) async {
    TextEditingController todoController = TextEditingController(
        text: todoData['title'] ?? '');

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme
                  .of(context)
                  .colorScheme
                  .inverseSurface,
              titleTextStyle: TextStyle(color: Theme
                  .of(context)
                  .colorScheme
                  .primary,),
              title: const Text("Edit Todo"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: todoController,
                    style: TextStyle(color: Theme
                        .of(context)
                        .colorScheme
                        .surface,),
                    decoration: InputDecoration(
                      labelText: "Edit your todo",
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
                    String updatedTodo = todoController.text.trim();
                    if (updatedTodo.isNotEmpty) {
                      await _editTodoAPI(todoData['id'], updatedTodo);
                    }
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: const Text(
                    "Update",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
    //print(response);
    if (response.statusCode == 204) {
      _initializeData();
      showAnimatedSnackBar(
          context, "$todoName Removed!", isSuccess: true,
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
    //TextEditingController todoController = TextEditingController();

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
                                "Todos",
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
                if (_isRefreshing)
                SliverToBoxAdapter(
                  child: CustomLoadingElement(bookController: _todoController,backgroundColor: Theme.of(context).colorScheme.primary,icon: Icons8.tasks,)
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // 🏁 Uncompleted Tasks Section
                      ..._todos
                          .where((todo) => !(todo['is_completed'] ?? false))
                          .map((todo) =>
                          Padding(
                            padding: EdgeInsets.only(
                                top: 12, left: 5, right: 5),
                            child: Slidable(
                              key: ValueKey(todo['id']),
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (context) async {
                                      await _deleteTodo(
                                          context, todo['id'], todo['title']);
                                    },
                                    backgroundColor: Theme
                                        .of(context)
                                        .colorScheme
                                        .error,
                                    foregroundColor: Theme
                                        .of(context)
                                        .colorScheme
                                        .errorContainer,
                                    icon: Icons.delete_forever,
                                    label: 'Delete',
                                  ),
                                ],
                              ),
                              child: ListTile(
                                textColor: Theme
                                    .of(context)
                                    .colorScheme
                                    .surface,
                                title: Text(
                                  todo['title'] ?? 'Untitled',
                                  style: TextStyle(
                                    color: Theme
                                        .of(context)
                                        .colorScheme
                                        .primary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Sora',
                                  ),
                                ),
                                subtitle: Text('Last updated: ${formatDateTime(
                                    todo['updated_at'])}'),
                                //trailing: IconButton(
                                //  onPressed: () async {
                                //    await _deleteTodo(
                                //        context, todo['id'], todo['title']);
                                //  },
                                //  icon: Icon(Icons.delete, color: Colors.grey),
                                //),
                                leading: IconButton(
                                  icon: Icon(Icons.check_circle),
                                  onPressed: () async {
                                    await _toggleCompleted(
                                        todo['id'], todo['title'], false);
                                  },
                                ),
                                onTap: () => _editTodo(context, todo),
                              ),
                            ),
                          ))
                          .toList(),

                      // ✅ Completed Section Collapsible Header
                      if (_todos.any((todo) => todo['is_completed'] == true))
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5.0, horizontal: 15.0),
                              child: const Divider(thickness: 1,),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isCompletedExpanded = !_isCompletedExpanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 18.0),
                                      child: Text(
                                        "Completed Todos",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          right: 18.0),
                                      child: Icon(
                                        _isCompletedExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),


                      // 🏁 Completed Tasks Section (shown only if expanded)
                      if (_isCompletedExpanded)
                        ..._todos
                            .where((todo) => todo['is_completed'] ?? false)
                            .map((todo) =>
                            Padding(
                              padding: EdgeInsets.only(
                                  top: 12, left: 5, right: 5),
                              child: ListTile(
                                textColor: Theme
                                    .of(context)
                                    .colorScheme
                                    .surface,
                                title: Text(
                                  todo['title'] ?? 'Untitled',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Sora',
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                subtitle: Text('Last updated: ${formatDateTime(
                                    todo['updated_at'])}'),
                                trailing: IconButton(
                                  onPressed: () async {
                                    await _deleteTodo(
                                        context, todo['id'], todo['title']);
                                  },
                                  icon: Icon(Icons.delete, color: Colors.grey),
                                ),
                                leading: IconButton(
                                  icon: Icon(Icons.done, color: Colors.green),
                                  onPressed: () async {
                                    await _toggleCompleted(
                                        todo['id'], todo['title'], true);
                                  },
                                ),
                                onTap: () => _editTodo(context, todo),
                              ),
                            ))
                            .toList(),
                    ],
                  ),
                ),

              ],
            ),
          ),
    );
  }
}
