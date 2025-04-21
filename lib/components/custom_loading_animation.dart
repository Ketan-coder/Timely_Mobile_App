import 'package:flutter/material.dart';
import 'package:flutter_animated_icons/icons8.dart';
import 'package:lottie/lottie.dart';

class CustomLoadingElement extends StatelessWidget {
  final AnimationController bookController;
  final Color iconColor;
  final VoidCallback? onPressed;

  final double width;
  final double height;
  final double lottieHeight;
  final double splashRadius;
  final double iconSize;

  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  final Color backgroundColor;
  final double borderRadius;
  final BoxFit fit;

  final String icon;

  const CustomLoadingElement({
    super.key,
    required this.bookController,
    this.iconColor = Colors.red,
    this.onPressed,
    this.width = 100,
    this.height = 100,
    this.lottieHeight = 60,
    this.splashRadius = 50,
    this.iconSize = 100,
    this.margin = const EdgeInsets.only(top: 200),
    this.padding = const EdgeInsets.all(2),
    this.backgroundColor = Colors.white,
    this.borderRadius = 10,
    this.fit = BoxFit.fitHeight,
    this.icon = Icons8.book,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: IconButton(
          splashRadius: splashRadius,
          iconSize: iconSize,
          color: iconColor,
          onPressed: onPressed ??
              () {
                print(bookController.status);
                if (bookController.isAnimating) {
                  bookController.reset();
                } else {
                  bookController.repeat();
                }
              },
          icon: Lottie.asset(
            icon,
            controller: bookController,
            height: lottieHeight,
            fit: fit,
            delegates: LottieDelegates(
              values: [
                ValueDelegate.color(
                  const ['*'],
                  value: iconColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
