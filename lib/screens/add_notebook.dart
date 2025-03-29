import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timely/auth/auth_service.dart' as auth_service;
import 'package:timely/components/bottom_nav_bar.dart';
import 'package:timely/components/custom_snack_bar.dart';
import 'package:timely/components/labels.dart';
import 'package:timely/components/text_field.dart';

import '../components/button.dart';

class AddNotebookPage extends StatefulWidget {
  const AddNotebookPage({super.key});

  @override
  State<AddNotebookPage> createState() => _AddNotebookPageState();
}

class _AddNotebookPageState extends State<AddNotebookPage> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _priority = TextEditingController();
  final TextEditingController _body = TextEditingController();

  // Todo-Add Notebook Logic with api calling
  Future<void> _addNotebook() async {

    if(_title.text.isEmpty){
      showAnimatedSnackBar(context, "Title cannot be Empty", isError: true,isTop: true);
      return;
    } else if (_priority.text.isEmpty) {
      showAnimatedSnackBar(
          context, "Priority cannot be Empty", isError: true, isTop: true);
      return;
    } else if (_priority.text.isNotEmpty &&
        int.tryParse(_priority.text) == null) {
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

    final url = Uri.parse(
        'https://timely.pythonanywhere.com/api/v1/notebooks/');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Token $token',
      },
      body: {
        'title': _title.text,
        'priority': _priority.text,
        'body': _body.text
      }
    );

    print("Raw API Response: ${response.body}"); // Debugging

    if (response.statusCode == 201) {
      FocusScope.of(context).unfocus();
      try {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        print(jsonResponse);
        showAnimatedSnackBar(
            context, "Notebook Added Successfully", isSuccess: true,
            isTop: true);
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => BottomNavBar(currentIndex: 0),),);
      } catch (e) {
        print("Error parsing response: $e");
        showAnimatedSnackBar(
            context, "Something Went Wrong!", isError: true, isTop: true);
      }
    } else {
      print("Failed to fetch notebooks: ${response.body}");
      showAnimatedSnackBar(context, "Something Went Wrong!", isError: true,isTop: true);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Notebook"),
        toolbarHeight: 60,
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        foregroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              MyLabel(
                text: "Title",
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              MyTextField(
                controller: _title,
                hintext: "Enter Title",
                obscuretext: false,
                prefixicon: Icon(Icons.title),
                width: 80,
                height: 20,
                maxlines: 1,
              ),
              MyLabel(
                text: "Priority",
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              MyTextField(
                controller: _priority,
                hintext: "Enter Priority",
                obscuretext: false,
                prefixicon: Icon(Icons.priority_high),
                width: 80,
                height: 20,
                maxlines: 1,
              ),
              MyLabel(
                text: "Body",
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              MyTextField(
                controller: _body,
                hintext: "Enter Body",
                obscuretext: false,
                prefixicon: Icon(Icons.text_fields),
                width: 80,
                height: 20,
                maxlines: 10,
              ),
              MyButton(onPressed: () => _addNotebook(), text: "Save"),
            ],
          ),
        ),
      ),
    );
  }
}
