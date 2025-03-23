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
    return Scaffold(
      appBar: AppBar(
        title:
            widget.isPasswordProtected
                ? Text("LOCKED NOTEBOOK")
                : Text("Notebook Details"),
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
