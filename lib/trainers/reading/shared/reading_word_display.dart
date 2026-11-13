import 'package:flutter/material.dart';

class ReadingWordDisplay extends StatelessWidget {
  const ReadingWordDisplay({super.key, required this.word});
  final String word;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SizedBox(
      width: box.maxWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          word,
          textDirection: TextDirection.ltr,
          locale: const Locale('ru'),
          style: TextStyle(
            fontSize: (box.maxWidth * 0.09).clamp(32, 80).toDouble(),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}
