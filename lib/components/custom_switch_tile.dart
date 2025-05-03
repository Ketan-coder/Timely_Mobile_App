import 'package:flutter/material.dart';

class CustomSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final Function(bool) onChanged;

  const CustomSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Sora',
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
