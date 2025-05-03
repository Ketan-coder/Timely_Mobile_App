import 'dart:convert';
import 'dart:io';
import 'package:flutter_animated_icons/icons8.dart';
import 'package:timely/components/custom_loading_animation.dart';
import 'package:timely/components/custom_snack_bar.dart';
import 'package:timely/services/internet_checker_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:timely/auth/auth_service.dart' as auth_service;
import 'package:timely/components/bottom_nav_bar.dart';

import '../utils/date_formatter.dart';

class SubPageDetailsPage extends StatefulWidget {
  final String subpageUuid;
  late bool canEdit;
  late bool canDelete;

  SubPageDetailsPage({super.key, required this.subpageUuid, this.canEdit = false, this.canDelete = false});

  @override
  State<SubPageDetailsPage> createState() => _SubPageDetailsPageState();
}

class _SubPageDetailsPageState extends State<SubPageDetailsPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _subpageData;
  bool _isLoading = true;
  String _errorMessage = "";
  late String _token;
  late InternetChecker _internetChecker;
  late AnimationController _bodyController;

  @override
  void initState() {
    super.initState();
    _internetChecker = InternetChecker(context);
    _internetChecker.startMonitoring();
    _loadTokenAndFetchSubpage();
    _bodyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _internetChecker.stopMonitoring();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadTokenAndFetchSubpage() async {
    String? token = await auth_service.AuthService.getToken(); // Await token
    if (token != null) {
      setState(() {
        _token = token;
      });
      _fetchSubPageDetails(); // Fetch notebook only after getting token
    } else {
      setState(() {
        _errorMessage = "Failed to retrieve authentication token.";
        _isLoading = false;
      });
    }
  }

    Future<void> _fetchSubPageDetails() async {
      final url = Uri.parse(
        'https://timely.pythonanywhere.com/api/v1/subpages/${widget.subpageUuid}/',
      );

      try {
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $_token',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            _subpageData = jsonDecode(response.body);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "Failed to load subpage.";
            _isLoading = false;
          });
        }
      } on SocketException catch (_) {
        showAnimatedSnackBar(
          context,
          "No internet connection. Please try again.",
          isError: true,
          isTop: true,
        );
        setState(() {
          _errorMessage = "No internet connection.";
          _isLoading = false;
        });
      } catch (e) {
        print("Unexpected error: $e");
        setState(() {
          _errorMessage = "Something went wrong.";
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
      'https://timely.pythonanywhere.com/api/v1/subpages/${widget.subpageUuid}/',
    );
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $_token', // Replace with actual token
      },
    );
    //print(response);
    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$pageName has been Deleted Successfully'),
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

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showAnimatedSnackBar(context, "Could not launch $url", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      appBar: AppBar(
        title: _isLoading ? Text("") : Text("${_subpageData?['title']}"),
        backgroundColor: Theme
            .of(context)
            .colorScheme.inverseSurface,
        foregroundColor: Theme
            .of(context)
            .colorScheme
            .secondary,
      ),
      persistentFooterButtons: [
       widget.canEdit ? Row(
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
            widget.canDelete ? Expanded(
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
                      _subpageData?['page_uuid'],
                      _subpageData?['title'],
                    );
                  },
                  icon: const Icon(Icons.delete_forever_rounded),
                ),
              ),
            ) : const SizedBox(),
          ],
        ) : SizedBox(),
      ],
      // floatingActionButton: FloatingActionButton(
      //   //check if the note is favorite or not and change the icon as needed
      //   onPressed: () => showPageBottomSheet(context),
      //   //check if the note is favorite or not and change the icon as needed
      //   child: const Icon(Icons.description_outlined, color: Colors.deepPurple),
      // ),
      body:
          _isLoading
              ? Center(child: 
                  CustomLoadingElement(
                    bookController: _bodyController,
                    icon: Icons8.book,
                    iconColor: Theme
                        .of(context)
                        .colorScheme
                        .surface,
                    backgroundColor: Theme
                        .of(context)
                        .colorScheme
                        .primary,
                    margin: const EdgeInsets.only(top: 50),
                  ))
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
                      _subpageData?['title'] ?? 'Untitled',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Text(
                      "Last Updated: ${formatDateTime(_subpageData?['updated_at'])}",
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
                          _subpageData?['body'] ??
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