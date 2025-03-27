import 'package:flutter/material.dart';
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
              MyButton(onPressed: () {}, text: "Save"),
            ],
          ),
        ),
      ),
    );
  }
}
