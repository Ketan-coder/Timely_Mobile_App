import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/auth_service.dart' as auth_service;
import 'package:flutter_html/flutter_html.dart';

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
      'https://timely.pythonanywhere.com/api/v1/notebooks/${widget
          .notebookId}/',
    );
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $_token', // Replace with actual token
      },
      body: jsonEncode({ 'is_favourite': !IsFavourite}),

    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked Favourite'),
          backgroundColor: Colors.green,),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong!'),
          backgroundColor: Colors.red,),
      );
    }
  }

  Future<void> _fetchNotebookDetails() async {
    final url = Uri.parse(
      'https://timely.pythonanywhere.com/api/v1/notebooks/${widget
          .notebookId}/',
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
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = "Failed to load notebook.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isFavourite = _notebookData?['is_favourite'] ?? false;
    return Scaffold(
      appBar: AppBar(
        title:
        widget.isPasswordProtected
            ? Text("LOCKED NOTEBOOK")
            : Text(""),
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
                    color: isFavourite
                        ? Colors.red[100]
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.deepPurple.shade100, width: 2),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      await _toggleIsFavourite(
                          _notebookData?['id'], isFavourite);
                    },
                    icon: isFavourite
                        ? const Icon(Icons.favorite, color: Colors.red)
                        : Icon(Icons.favorite_border,
                        color: Colors.deepPurple.shade100),
                  ),
                )),
            Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.all(5),
                  // color: Colors.black,
                  decoration: BoxDecoration(
                    // color: note.isFavorite ? Colors.red : Colors.deepPurple[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.deepPurple.shade100, width: 2),
                  ),
                  child: IconButton(
                    onPressed: () {
                      print('Pressed');
                    },
                    icon: const Icon(Icons.delete_forever_rounded),
                  ),
                )),
          ],
        ),
      ],
      floatingActionButton: FloatingActionButton(
        //check if the note is favorite or not and change the icon as needed
        onPressed: () {},
        //check if the note is favorite or not and change the icon as needed
        child: const Icon(Icons.edit, color: Colors.deepPurple),
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
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Html(
                  data:
                  _notebookData?['body'] ??
                      "<p>No content available</p>",
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
