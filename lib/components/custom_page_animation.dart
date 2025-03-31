import 'package:flutter/material.dart';

// Custom transition (right-to-left, slow like iOS)
Route createRoute(Widget secondScreen) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 600), // Slow transition
    pageBuilder: (context, animation, secondaryAnimation) => secondScreen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0); // Start from the right
      const end = Offset.zero; // End at the center
      const curve = Curves.easeInOut; // Smooth slow effect

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}
