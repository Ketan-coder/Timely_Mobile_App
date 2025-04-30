import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintext;
  final List<String>? hintTexts;
  final bool obscuretext;
  final prefixicon;
  final double width;
  final double height;
  final int maxlines;
  final suffixicon;
  final onChanged;
  final onTap;
  final String? errorText;
  final String? labelText;

  const MyTextField({super.key,
    required this.controller,
    required this.hintext,
    this.hintTexts,
    required this.obscuretext,
    this.prefixicon,
    required this.width,
    required this.height,
    required this.maxlines,
    this.suffixicon,
    this.onChanged,
    this.errorText,
    this.labelText,
    this.onTap,
  });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  String _currentHint = '';
  int _hintIndex = 0;
  int _charIndex = 0;
  bool _isTyping = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    if (widget.hintTexts != null && widget.hintTexts!.isNotEmpty) {
      _startTypingAnimation();
    } else if (widget.hintext != null) {
      _currentHint = widget.hintext!;
    }
  }

  @override
  void didUpdateWidget(covariant MyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hintTexts != oldWidget.hintTexts && widget.hintTexts != null &&
        widget.hintTexts!.isNotEmpty) {
      _hintIndex = 0;
      _charIndex = 0;
      _isTyping = false;
      _currentHint = '';
      _startTypingAnimation();
    } else
    if (widget.hintext != oldWidget.hintext && widget.hintTexts == null) {
      setState(() {
        _currentHint = widget.hintext ?? '';
      });
    }
  }

  void _startTypingAnimation() {
    if (!mounted || widget.hintTexts == null || widget.hintTexts!.isEmpty) {
      return;
    }

    _isTyping = true;
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && _isTyping) {
        final currentText = widget.hintTexts![_hintIndex];
        if (_charIndex < currentText.length) {
          setState(() {
            _currentHint = currentText.substring(0, _charIndex + 1);
            _charIndex++;
          });
          _startTypingAnimation(); // Continue typing
        } else {
          _isTyping = false;
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && widget.hintTexts != null) {
              _hintIndex = (_hintIndex + 1) % widget.hintTexts!.length;
              _charIndex = 0;
              _currentHint = '';
              _startTypingAnimation(); // Start typing the next hint
            }
          });
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        onTap: widget.onTap,
        style: TextStyle(
          color: Theme
              .of(context)
              .colorScheme
              .surface,
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inverseSurface,
        ),
        controller: widget.controller,
        obscureText: widget.obscuretext ? !_showPassword : widget.obscuretext,
        maxLines: widget.maxlines,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          errorText: widget.errorText,
          labelText: widget.labelText,
          errorStyle: TextStyle(
            color: Theme
                .of(context)
                .colorScheme
                .error,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 2, color: Theme
                .of(context)
                .colorScheme
                .primary),
          ),
          contentPadding: EdgeInsets.symmetric(
              horizontal: widget.width, vertical: widget.height),
          // Adjust these values.
          prefixIcon: widget.prefixicon,
          suffixIcon: widget.obscuretext
              ? IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                )
              : widget.suffixicon,
          fillColor: Theme
              .of(context)
              .colorScheme
              .inverseSurface,
          filled: true,
          hintText: _currentHint,
          // keyboardType: TextInputType.number,
          // inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          hintStyle: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }
}
