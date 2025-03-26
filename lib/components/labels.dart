import 'package:flutter/material.dart';

class MyLabel extends StatelessWidget {
  final String text;
  const MyLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.only(top: 5, left: 12, bottom: 0, right: 8),
      child: Text(text,
      textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
          )),
    );
  }
}
