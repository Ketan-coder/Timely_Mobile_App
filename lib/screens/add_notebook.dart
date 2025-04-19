import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timely/auth/auth_service.dart' as auth_service;
import 'package:timely/components/bottom_nav_bar.dart';
import 'package:timely/components/button.dart';
import 'package:timely/components/custom_snack_bar.dart';
import 'package:timely/components/labels.dart';

class AddNotebookPage extends StatefulWidget {
  final int? notebookId;

  AddNotebookPage({super.key, this.notebookId});

  @override
  State<AddNotebookPage> createState() => _AddNotebookPageState();
}

class _AddNotebookPageState extends State<AddNotebookPage> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _priority = TextEditingController();
  final TextEditingController _body = TextEditingController();

  @override
  void initState() {
    if (widget.notebookId != null) {
      _fetchNotebookDetails(widget.notebookId!);
    }
    super.initState();
  }


  Future <void> _fetchNotebookDetails(int notebookId) async {
    final token = await auth_service.AuthService.getToken();
    final response = await auth_service.AuthService.fetchNotebookDetails(
        token!, notebookId);
    print("Response=>>");
    print(response);
    setState(() {
      _title.text = response?['title'];
      _priority.text = response!['priority'].toString();
      _body.text = response['body'];
    });
  }

  Future<void> _addNotebook({String? notebookId}) async {
    if (_title.text.isEmpty) {
      showAnimatedSnackBar(
          context, "Title cannot be Empty", isError: true, isTop: true);
      return;
    } else if (_priority.text.isEmpty) {
      showAnimatedSnackBar(
          context, "Priority cannot be Empty", isError: true, isTop: true);
      return;
    } else
    if (_priority.text.isNotEmpty && int.tryParse(_priority.text) == null) {
      showAnimatedSnackBar(
          context, "Priority must be a number", isError: true, isTop: true);
      return;
    } else if (_priority.text.isNotEmpty &&
        (int.tryParse(_priority.text)! > 5 ||
            int.tryParse(_priority.text)! < 0)) {
      showAnimatedSnackBar(
          context, "Priority must be between 1 to 5, not more neither less!",
          isError: true, isTop: true);
      return;
    } else if (_body.text.isEmpty) {
      showAnimatedSnackBar(
          context, "Body cannot be Empty", isError: true, isTop: true);
      return;
    }

    final token = await auth_service.AuthService.getToken();


    final url = notebookId != null ? Uri.parse(
        'https://timely.pythonanywhere.com/api/v1/notebooks/$notebookId/') : Uri
        .parse('https://timely.pythonanywhere.com/api/v1/notebooks/');
    final response = notebookId != null ? await http.patch(
      url,
      headers: {
        'Authorization': 'Token $token',
      },
      body: {
        'title': _title.text,
        'priority': _priority.text,
        'body': _body.text,
      },
    ) : await http.post(
      url,
      headers: {
        'Authorization': 'Token $token',
      },
      body: {
        'title': _title.text,
        'priority': _priority.text,
        'body': _body.text
      },
    );

    if (response.statusCode == 201) {
      FocusScope.of(context).unfocus();
      try {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        showAnimatedSnackBar(
            context, "Notebook Added Successfully", isSuccess: true,
            isTop: true);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BottomNavBar(currentIndex: 0)),
        );
      } catch (e) {
        showAnimatedSnackBar(
            context, "Something Went Wrong!", isError: true, isTop: true);
      }
    } else if (response.statusCode == 200) {
      FocusScope.of(context).unfocus();
      showAnimatedSnackBar(
          context, "Notebook Edited Successfully", isSuccess: true,
          isTop: true);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BottomNavBar(currentIndex: 0)),
      );
    } else {
      showAnimatedSnackBar(
          context, "Something Went Wrong!", isError: true, isTop: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      appBar: AppBar(
        title: Text(widget.notebookId != null ? "Edit Notebook" : "Add Notebook"),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BottomNavBar(currentIndex: 0),
            ),
          );
        },
        child: const Icon(Icons.close),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 16.0),
              child: TextField(
                controller: _title,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "Title",
                  border: InputBorder.none,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _body,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText: "Note",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          MyLabel(text: 'Priority:', size: 15, color: Theme
                              .of(context)
                              .colorScheme
                              .surface),
                          SizedBox(width: 15),
                          Expanded(
                            child: TextField(
                              controller: _priority,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Priority (1-5)",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
                MyButton(onPressed: widget.notebookId != null
                    ? () =>
                    _addNotebook(notebookId: widget.notebookId.toString())
                    : _addNotebook,
                    text: widget.notebookId != null
                        ? 'Edit Notebook'
                        : 'Add Notebook',
                    isGhost: true,
                    margin: 18),
              ],
            )
          ],
        ),
      ),
    );
  }
}
