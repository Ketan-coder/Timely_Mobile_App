import 'dart:convert';
import 'package:timely/screens/subpage_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/auth/auth_service.dart' as auth_service;
import 'package:timely/components/bottom_nav_bar.dart';

import '../utils/date_formatter.dart';

class PageDetailsPage extends StatefulWidget {
  final String pageUuid;

  PageDetailsPage({super.key, required this.pageUuid});

  @override
  State<PageDetailsPage> createState() => _PageDetailsPageState();
}

class _PageDetailsPageState extends State<PageDetailsPage> {
  Map<String, dynamic>? _pageData;
  bool _isLoading = true;
  String _errorMessage = "";
  late String _token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchNotebook();
  }

  Future<void> _loadTokenAndFetchNotebook() async {
    String? token = await auth_service.AuthService.getToken(); // Await token
    if (token != null) {
      setState(() {
        _token = token;
      });
      _fetchPageDetails(); // Fetch notebook only after getting token
    } else {
      setState(() {
        _errorMessage = "Failed to retrieve authentication token.";
        _isLoading = false;
      });
    }
  }

    Future<void> _fetchPageDetails() async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/pages/${widget.pageUuid}/',
    );
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $_token', // Replace with actual token
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _pageData = jsonDecode(response.body);
        print(_pageData);
        _isLoading = false;
      });

    } else {
      setState(() {
        _errorMessage = "Failed to load notebook.";
        _isLoading = false;
      });
    }
  }

    Future<void> _showDeleteConfirmationDialog(
    String pageUuid,
    String pageName,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevent dialog from closing when tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          title: const Text("Delete Notebook"),
          content: Text(
            "Are you sure you want to delete '$pageName'? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed:
                  () => Navigator.of(context).pop(), // ❌ Cancel (Close Dialog)
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // ✅ Close dialog before deletion
                await _deletePage(pageUuid, pageName);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

    Future<void> _deletePage(String pageUuid, String pageName) async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/pages/${widget.pageUuid}/',
    );
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $_token', // Replace with actual token
      },
    );
    print(response);
    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pageName} has been Deleted Successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const BottomNavBar(currentIndex: 0),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong!'),
          backgroundColor: Colors.red,
        ),
      );
    }
    }

    Future<List<Map<String, dynamic>>> _fetchPagesDetailsForSubpages({bool forceRefresh = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // final String? cachedData = prefs.getString('notebook_${widget.notebookId}');

    // // Return cached data if available
    // if (cachedData != null) {
    //   return List<Map<String, dynamic>>.from(jsonDecode(cachedData));
    // }
    if (!forceRefresh) {
      final String? cachedData = prefs.getString('page_${widget.pageUuid}');
      if (cachedData != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cachedData));
      }
    }
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/pages/${widget.pageUuid}/',
    );
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $_token', // Replace with actual token
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _pageData = jsonDecode(response.body);
        print(_pageData);
        _isLoading = false;
      });

      final Map<String, dynamic> pageData = jsonDecode(response.body);
      // final List<String> pageUuids = List<String>.from(notebookData['pages'] ?? []);
      final List<String> subpageUuids = List<String>.from(pageData['subpages'] ?? []);

      if (subpageUuids.isEmpty) {
        return []; // No pages found
      }

      // Fetch pages in parallel instead of sequentially
      final List<Map<String, dynamic>?> pages = await Future.wait(
        subpageUuids.map((uuid) => auth_service.AuthService.fetchSubPageDetails(uuid, _token)),
      );

      // Remove null results (failed fetches)
      final List<Map<String, dynamic>> validPages =
          pages.where((page) => page != null).cast<Map<String, dynamic>>().toList();

      // Cache the fetched pages
      await auth_service.AuthService.savePagesLocally(pageData['id'], validPages);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('page_${widget.pageUuid}', jsonEncode(validPages));

      return validPages;
    } else {
      setState(() {
        _errorMessage = "Failed to load notebook.";
        _isLoading = false;
      });
      return [];
    }
  }

  Future<void> showPageBottomSheet(BuildContext context) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Keeps background visible
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<List<Map<String, dynamic>>> _pageFuture = _fetchPagesDetailsForSubpages();

          Future<void> refreshPages() async {
            setState(() {
              _pageFuture = _fetchPagesDetailsForSubpages(forceRefresh: true);
            });
          }

          return FractionallySizedBox(
            heightFactor: 0.45, // Covers 1/4th of the screen initially
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inverseSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // Handle for Dragging
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Header with Refresh Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Sub Pages",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: refreshPages, // Refresh button
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _pageFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text("Error: ${snapshot.error}"));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              "No Pages Found!",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 20,
                              ),
                            ),
                          );
                        } else {
                          final pages = snapshot.data!;
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: pages.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(context,MaterialPageRoute(builder: (context) => SubPageDetailsPage(subpageUuid: pages[index]['subpage_uuid'],),),);
                                },
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.tertiary,
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.tertiary,
                                        width: 5.0,
                                      ),
                                    ),
                                    child: Text(
                                      "${index + 1}",
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.surface,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    pages[index]['title'] ?? "Untitled Page",
                                    style: TextStyle(color: Theme.of(context).colorScheme.surface),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      appBar: AppBar(
        title: _isLoading ? Text("") : Text("${_pageData?['title']}"),
        backgroundColor: Theme
            .of(context)
            .colorScheme.inverseSurface,
        foregroundColor: Theme
            .of(context)
            .colorScheme
            .secondary,
      ),
      persistentFooterButtons: [
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.all(5),
                // color: Colors.black,
                decoration: BoxDecoration(
                  // color: note.isFavorite ? Colors.red : Colors.deepPurple[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.deepPurple.shade100,
                    width: 2,
                  ),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.all(5),
                // color: Colors.black,
                decoration: BoxDecoration(
                  // color: note.isFavorite ? Colors.red : Colors.deepPurple[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.deepPurple.shade100,
                    width: 2,
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    _showDeleteConfirmationDialog(
                      _pageData?['page_uuid'],
                      _pageData?['title'],
                    );
                  },
                  icon: const Icon(Icons.delete_forever_rounded),
                ),
              ),
            ),
          ],
        ),
      ],
      floatingActionButton: FloatingActionButton(
        //check if the note is favorite or not and change the icon as needed
        onPressed: () => showPageBottomSheet(context),
        //check if the note is favorite or not and change the icon as needed
        child: const Icon(Icons.description_outlined, color: Colors.deepPurple),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pageData?['title'] ?? 'Untitled',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Text(
                      "Last Updated: ${formatDateTime(
                          _pageData?['updated_at'])}",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Sora',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Html(
                          data:
                          _pageData?['body'] ??
                              "<p>No content available</p>",
                          onAnchorTap: (url, context, attributes) {
                            if (url != null) {
                              _launchUrl(url);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}