import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintext;
  final bool obscuretext;
  final prefixicon;
  final double width;
  final double height;
  final int maxlines;
  final suffixicon;

  const MyTextField({super.key,
    required this.controller,
    required this.hintext,
    required this.obscuretext,
    this.prefixicon,
    required this.width,
    required this.height,
    required this.maxlines,
    this.suffixicon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        controller: controller,
        obscureText: obscuretext,
        maxLines: maxlines,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 2, color: Theme
                .of(context)
                .colorScheme
                .primary),
          ),
          contentPadding: EdgeInsets.symmetric(
              horizontal: width, vertical: height),
          // Adjust these values.
          prefixIcon: prefixicon,
          suffixIcon: suffixicon,
          fillColor: Theme
              .of(context)
              .colorScheme
              .inverseSurface,
          filled: true,
          hintText: hintext,
          // keyboardType: TextInputType.number,
          // inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          hintStyle: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }
}
