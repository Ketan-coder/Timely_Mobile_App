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
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: Colors.black,
              expandedHeight: 190.0,
              floating: false,
              pinned: true,
              snap: false,
              toolbarHeight: 60.0,
              actions: [
                IconButton(onPressed: () async {
                  await _logout;
                }, icon: Icon(Icons.logout), color: Theme
                    .of(context)
                    .colorScheme
                    .primary,)
              ],
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return FlexibleSpaceBar(
                    centerTitle: true,
                    //title: Text(
                    //  "Notes",
                    //  style: TextStyle(
                    //    color: Theme.of(context).colorScheme.tertiary ?? Colors.white, // Default fallback color
                    //    fontSize: 20.0,
                    //    fontWeight: FontWeight.w400,
                    //  ),
                    //),
                    expandedTitleScale: 2,
                    background: Image.network(
                      "https://th.bing.com/th/id/OIP.YRIUUjhcIMvBEf_bbOdpUwHaEU?rs=1&pid=ImgDetMain",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey,
                          // ✅ Fallback background if image fails
                          child: const Center(
                              child: Text("Image failed to load")),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

          ];
        },
        body: _notebooks.isEmpty
            ? const Center(child: Text('No notebooks found!'))
            : ListView.builder(
          itemCount: _notebooks.length,
          itemBuilder: (context, index) {
            final notebook = _notebooks[index];
            bool isProtected = notebook['is_password_protected'] ??
                false; // ✅ Null-safety fix

            return ListTile(
              textColor: Theme
                  .of(context)
                  .colorScheme
                  .primary,
              title: Text(notebook['title'] ?? 'Untitled'),
              subtitle: Text('Last updated: ${notebook['updated_at']}'),
              trailing: isProtected
                  ? const Icon(Icons.lock, color: Colors.red)
                  : const SizedBox(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotebookDetailPage(
                          notebookId: notebook['id'],
                          isPasswordProtected: isProtected,
                        ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
