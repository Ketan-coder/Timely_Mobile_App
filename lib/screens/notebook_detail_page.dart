import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/components/custom_snack_bar.dart';
import 'package:timely/components/labels.dart';
import 'package:timely/screens/page_detail_page.dart';
import 'dart:convert';
import '../auth/auth_service.dart' as auth_service;
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/bottom_nav_bar.dart';
import 'package:intl/intl.dart';

class NotebookDetailPage extends StatefulWidget {
  final int notebookId;
  final bool isPasswordProtected;

  NotebookDetailPage({
    super.key,
    required this.notebookId,
    this.isPasswordProtected = false,
  });

  @override
  State<NotebookDetailPage> createState() => _NotebookDetailPageState();
}

class _NotebookDetailPageState extends State<NotebookDetailPage> {
  Map<String, dynamic>? _notebookData;
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
      _fetchNotebookDetails(); // Fetch notebook only after getting token
    } else {
      setState(() {
        _errorMessage = "Failed to retrieve authentication token.";
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleIsFavourite(int notebookID, bool IsFavourite) async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/notebooks/${widget.notebookId}/',
    );
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $_token', // Replace with actual token
      },
      body: jsonEncode({'is_favourite': !IsFavourite}),
    );
    if (response.statusCode == 200) {
      IsFavourite ? showAnimatedSnackBar(
          context, "Unhearted", isSuccess: true,
          isTop: true) : showAnimatedSnackBar(
          context, "Marked Favourite", isSuccess: true,
          isTop: true);
      setState(() {
        IsFavourite = !IsFavourite;
      });
    } else {
      showAnimatedSnackBar(
          context, "Something Went Wrong", isError: true,
          isTop: true);
    }
  }

  Future<void> _deleteNotebook(int notebookID, String NotebookName) async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/notebooks/${widget.notebookId}/',
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
      showAnimatedSnackBar(context, "${NotebookName} has been Deleted Successfully", isSuccess: true,isTop: true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const BottomNavBar(currentIndex: 0),
        ),
      );
    } else {
      showAnimatedSnackBar(context, "Something went wrong!", isError: true,isTop: true);
    }
  }

  Future<void> _fetchNotebookDetails() async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/notebooks/${widget.notebookId}/',
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
        _notebookData = jsonDecode(response.body);
        print(_notebookData);
        _isLoading = false;
      });
    } else if (response.statusCode == 404) {
      setState(() {
        _errorMessage = "404 - No Notebook Found!";
        _isLoading = false;
      });
      showAnimatedSnackBar(
          context, "404 - No Notebook Found!", isError: true,
          isTop: true);
    }
    else {
      setState(() {
        _errorMessage = "Failed to load notebook.";
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNotebookDetailsForPages({bool forceRefresh = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // final String? cachedData = prefs.getString('notebook_${widget.notebookId}');

    // // Return cached data if available
    // if (cachedData != null) {
    //   return List<Map<String, dynamic>>.from(jsonDecode(cachedData));
    // }
    if (!forceRefresh) {
      final String? cachedData = prefs.getString('notebook_${widget.notebookId}');
      if (cachedData != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cachedData));
      }
    }
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/notebooks/${widget.notebookId}/',
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
        _notebookData = jsonDecode(response.body);
        print(_notebookData);
        _isLoading = false;
      });

      final Map<String, dynamic> notebookData = jsonDecode(response.body);
      final List<String> pageUuids = List<String>.from(notebookData['pages'] ?? []);
      final List<String> subpageUuids = List<String>.from(notebookData['subpages'] ?? []);

      if (pageUuids.isEmpty) {
        return []; // No pages found
      }

      // Fetch pages in parallel instead of sequentially
      final List<Map<String, dynamic>?> pages = await Future.wait(
        pageUuids.map((uuid) => auth_service.AuthService.fetchPageDetails(uuid, _token)),
      );

      // Remove null results (failed fetches)
      final List<Map<String, dynamic>> validPages =
          pages.where((page) => page != null).cast<Map<String, dynamic>>().toList();

      // Cache the fetched pages
      await auth_service.AuthService.savePagesLocally(notebookData['id'], validPages);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('notebook_${widget.notebookId}', jsonEncode(validPages));

      return validPages;
    } else {
      setState(() {
        _errorMessage = "Failed to load notebook.";
        _isLoading = false;
      });
      return [];
    }
  }


  Future<void> _showDeleteConfirmationDialog(
    int notebookID,
    String notebookName,
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
            "Are you sure you want to delete '$notebookName'? This action cannot be undone.",
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
                await _deleteNotebook(notebookID, notebookName);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> showPageBottomSheet(BuildContext context) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Keeps background visible
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<List<Map<String, dynamic>>> _pageFuture = _fetchNotebookDetailsForPages();

          Future<void> refreshPages() async {
            setState(() {
              _pageFuture = _fetchNotebookDetailsForPages(forceRefresh: true);
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
                          "Pages",
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
                                  Navigator.push(context,MaterialPageRoute(builder: (context) => PageDetailsPage(pageUuid: pages[index]['page_uuid'],),),);
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
    bool isFavourite = _notebookData?['is_favourite'] ?? false;
    return Scaffold(
      appBar: AppBar(
        title: widget.isPasswordProtected ? Text("LOCKED NOTEBOOK") : Text(""),
        backgroundColor: Theme
            .of(context)
            .scaffoldBackgroundColor,
        foregroundColor: Theme
            .of(context)
            .colorScheme
            .primary,
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
                  color: isFavourite ? Colors.red[100] : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.deepPurple.shade100,
                    width: 2,
                  ),
                ),
                child: IconButton(
                  onPressed: () async {
                    await _toggleIsFavourite(_notebookData?['id'], isFavourite);
                  },
                  icon:
                      isFavourite
                          ? const Icon(Icons.favorite, color: Colors.red)
                          : Icon(
                            Icons.favorite_border,
                            color: Colors.deepPurple.shade100,
                          ),
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
                      _notebookData?['id'],
                      _notebookData?['title'],
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
                      _notebookData?['title'] ?? 'Untitled',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Sora',
                        color: Theme
                            .of(context)
                            .colorScheme
                            .tertiary,
                      ),
                    ),
                    Text(
                      "Last Updated: ${_formatDateTime(
                          _notebookData?['updated_at'])}",
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
                          //doNotRenderTheseTags: {'iframe','form'},
                          data:
                              _notebookData?['body'] ??
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
