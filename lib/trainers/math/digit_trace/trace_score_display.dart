import 'package:flutter/material.dart';

class TraceScoreDisplay extends StatelessWidget {
  const TraceScoreDisplay({
    super.key,
    required this.percent,
  });

  final int percent;

  Color get _color {
    if (percent >= 70) {
      return const Color(0xFF16A34A);
    }
    if (percent >= 45) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFFF43F5E);
  }

  String get _message {
    if (percent >= 85) {
      return 'Отлично получилось!';
    }
    if (percent >= 65) {
      return 'Хорошая обводка!';
    }
    if (percent >= 45) {
      return 'Уже похоже — попробуй ещё раз!';
    }
    return 'Попробуй обвести по пунктиру ещё раз';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'ПОХОЖЕСТЬ НА ЦИФРУ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$percent%',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: _color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _color,
          ),
        ),
      ],
    );
  }
}
