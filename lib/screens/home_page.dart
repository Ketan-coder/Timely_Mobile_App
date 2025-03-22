import 'package:flutter/material.dart';
import '../auth/auth_service.dart' as auth_service;
import '../models/notebook.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _notebooks = [];

  @override
  void initState() {
    super.initState();
    _loadNotebooks();
  }

  Future<void> _loadNotebooks() async {
    try {
      List<Notebook> notebooks =
          await auth_service.AuthService.loadNotebooksFromLocal();

      setState(() {
        _notebooks = notebooks.map((notebook) => notebook.toJson()).toList();
      });

      //print("Notebooks Loaded: $_notebooks"); // Debugging
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body:
          _notebooks.isEmpty
              ? const Center(child: Text('No notebooks found!'))
              : ListView.builder(
                itemCount: _notebooks.length,
                itemBuilder: (context, index) {
                  final notebook = _notebooks[index];
                  return ListTile(
                    title: Text(notebook['title'] ?? 'Untitled'),
                    subtitle: Text('Last updated: ${notebook['updated_at']}'),
                    onTap: () {
                      // TODO: Navigate to a detailed notebook view page
                    },
                  );
                },
              ),
    );
  }
}
