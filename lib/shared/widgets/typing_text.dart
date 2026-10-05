import 'dart:async';
import 'package:flutter/material.dart';
import 'package:characters/characters.dart';

class TypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final TextAlign? textAlign;

  const TypingText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 50),
    this.textAlign,
  });

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  String _displayedText = "";
  Timer? _timer;
  int _charIndex = 0;
  late List<String> _characters;

  @override
  void initState() {
    super.initState();
    // Use runes or .characters to handle surrogate pairs (emojis) correctly
    _characters = widget.text.characters.toList();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.duration, (timer) {
      if (_charIndex < _characters.length) {
        setState(() {
          _displayedText += _characters[_charIndex];
          _charIndex++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
