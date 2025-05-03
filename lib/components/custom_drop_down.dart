import 'package:flutter/material.dart';

class CustomDropdownTile<T> extends StatelessWidget {
  final String title;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?) onChanged;

  const CustomDropdownTile({
    super.key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Sora',
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
      trailing: Padding(
        padding: const EdgeInsets.all(5.0),
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(color: Theme.of(context).colorScheme.surface),
        ),
      ),
    );
  }
}
