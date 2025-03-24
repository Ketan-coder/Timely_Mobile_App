import 'package:flutter/material.dart';
import 'package:timely/screens/notebook_detail_page.dart';
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
  final double _titleOpacity = 1.0; // Controls title visibility

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
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          // setState(() {
          //   _titleOpacity = (1 - (scrollInfo.metrics.pixels / 100)).clamp(0, 1);
          // });
          return true;
        },
        child: CustomScrollView(
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
                      child: Text(
                        "Notebooks",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary ?? Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final notebook = _notebooks[index];
                  bool isProtected = notebook['is_password_protected'] ?? false;
                  return ListTile(
                    textColor: Theme.of(context).colorScheme.surface,
                    title: Text(notebook['title'] ?? 'Untitled'),
                    subtitle: Text('Last updated: ${notebook['updated_at']}'),
                    trailing: isProtected
                        ? const Icon(Icons.lock, color: Colors.red)
                        : const SizedBox(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotebookDetailPage(
                            notebookId: notebook['id'],
                            isPasswordProtected: isProtected,
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: _notebooks.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
