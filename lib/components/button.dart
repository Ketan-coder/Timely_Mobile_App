import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MyButton extends StatelessWidget {
  final void Function()? onPressed;
  final String text;
  bool isGhost;
  bool isSmall;
  double margin;

  MyButton({super.key,
    required this.onPressed,
    required this.text,
    this.isSmall = false,
    this.isGhost = false,
    this.margin = 10.0
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: isSmall ? EdgeInsets.all(5) : EdgeInsets.all(margin),
        padding: isSmall
            ? EdgeInsets.symmetric(horizontal: 10, vertical: 5)
            : EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: isGhost
              ? Colors.transparent
              : Theme
              .of(context)
              .colorScheme
              .primary,
          // color: Theme.of(context).colorScheme.primary,
          borderRadius: isSmall ? BorderRadius.circular(5) : BorderRadius
              .circular(10),
          border: isGhost
              ? Border.all(color: Theme
              .of(context)
              .colorScheme
              .primary)
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
                color: isGhost
                    ? Theme
                    .of(context)
                    .colorScheme
                    .primary
                    : Theme
                    .of(context)
                    .colorScheme
                    .inverseSurface,
                fontWeight: isGhost ? FontWeight.normal : FontWeight.bold,
                fontSize: isSmall ? 16 : 20),
          ),
        ),
      ),
    );
  }
}
