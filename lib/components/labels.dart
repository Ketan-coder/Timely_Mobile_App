import 'package:flutter/material.dart';

class MyLabel extends StatelessWidget {
  final String text;
  final double? size;
  final Color color;
  final bool? verticalPaddingZero;
  final bool? isUnderline;
  final bool? isTitle;
  final bool? shouldHaveWeight;

  const MyLabel({super.key,
    required this.text,
    this.verticalPaddingZero,
    required this.size,
    this.isUnderline,
    this.isTitle,
    this.shouldHaveWeight,
    required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: Container(
          margin: verticalPaddingZero == true
              ? EdgeInsets.all(0)
              : EdgeInsets.all(5),
          child: Text(text,
              style: TextStyle(
                  color: color,
                  fontSize: size,
                  decoration: isUnderline == true
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationColor:
                  isUnderline == true ? color : Colors.transparent,
                  fontWeight: size != null && size! > 20
                      ? FontWeight.bold
                      : shouldHaveWeight == true ? FontWeight.bold : FontWeight
                      .normal),
              textAlign: TextAlign.left),
        ),
      ),
    );
  }
}
