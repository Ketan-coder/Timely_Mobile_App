import 'package:flutter/material.dart';

void showAnimatedSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
  bool isInfo = false,
  bool isWarning = false,
  Color? backgroundColor,
  int duration = 3,
  bool isTop = false, // NEW: Show snackbar at the top or bottom
}) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) {
      return Positioned(
        top: isTop ? 80 : null,
        // Place at top if true
        bottom: isTop ? null : 50,
        // Place at bottom if false
        left: 20,
        right: 20,
        child: _AnimatedSnackBarWidget(
          message: message,
          isError: isError,
          isSuccess: isSuccess,
          isInfo: isInfo,
          isWarning: isWarning,
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
    },
  );

  overlay.insert(overlayEntry);

  Future.delayed(Duration(seconds: duration + 1), () {
    overlayEntry.remove();
  });
}

class _AnimatedSnackBarWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isSuccess;
  final bool isInfo;
  final bool isWarning;
  final Color? backgroundColor;
  final int duration;

  const _AnimatedSnackBarWidget({
    Key? key,
    required this.message,
    required this.isError,
    required this.isSuccess,
    required this.isInfo,
    required this.isWarning,
    this.backgroundColor,
    required this.duration,
  }) : super(key: key);

  @override
  _AnimatedSnackBarWidgetState createState() => _AnimatedSnackBarWidgetState();
}

class _AnimatedSnackBarWidgetState extends State<_AnimatedSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(Duration(seconds: widget.duration), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor =
        widget.backgroundColor ??
        (widget.isError
            ? Colors.red.shade900
            : widget.isSuccess
            ? Colors.green.shade700
            : widget.isInfo
            ? Colors.blue.shade600
            : widget.isWarning
            ? Colors.amber.shade700
            : Colors.black87);

    final Color textColor =
        (bgColor.computeLuminance() > 0.5) ? Colors.black : Colors.white;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Text(
              widget.message,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
