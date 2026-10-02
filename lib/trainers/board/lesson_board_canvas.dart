import 'dart:math' as math;

import 'package:flutter/material.dart';

class LessonBoardStroke {
  const LessonBoardStroke({required this.points, required this.color, required this.width});

  final List<Offset> points;
  final Color color;
  final double width;

  static List<LessonBoardStroke> fromElements(Object? elements) {
    if (elements is! List) {
      return const [];
    }

    final strokes = <LessonBoardStroke>[];
    for (final item in elements) {
      if (item is! Map) {
        continue;
      }
      if (item['type'] != 'freedraw' || item['isDeleted'] == true) {
        continue;
      }
      final raw = item['points'];
      if (raw is! List) {
        continue;
      }
      final originX = _number(item['x']);
      final originY = _number(item['y']);
      final points = <Offset>[];
      for (final point in raw) {
        if (point is! List || point.length < 2) {
          continue;
        }
        points.add(Offset(originX + _number(point[0]), originY + _number(point[1])));
      }
      if (points.isEmpty) {
        continue;
      }
      strokes.add(
        LessonBoardStroke(
          points: points,
          color: _color(item['strokeColor']),
          width: _number(item['strokeWidth']).clamp(1, 24).toDouble(),
        ),
      );
    }
    return strokes;
  }
}

class LessonBoardCanvas extends StatelessWidget {
  const LessonBoardCanvas({required this.strokes, this.canDraw = false, super.key});

  final List<LessonBoardStroke> strokes;
  final bool canDraw;

  @override
  Widget build(BuildContext context) {
    final view = CustomPaint(
      painter: _BoardPainter(strokes),
      child: const SizedBox.expand(),
    );
    if (canDraw) {
      return view;
    }
    return IgnorePointer(child: view);
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter(this.strokes);

  final List<LessonBoardStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFFCF8));
    if (strokes.isEmpty || size.isEmpty) {
      return;
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    for (final stroke in strokes) {
      for (final point in stroke.points) {
        minX = math.min(minX, point.dx);
        minY = math.min(minY, point.dy);
        maxX = math.max(maxX, point.dx);
        maxY = math.max(maxY, point.dy);
      }
    }

    const pad = 24.0;
    final contentWidth = math.max(maxX - minX, 1);
    final contentHeight = math.max(maxY - minY, 1);
    final scale = math.min((size.width - pad * 2) / contentWidth, (size.height - pad * 2) / contentHeight);
    final offsetX = (size.width - contentWidth * scale) / 2 - minX * scale;
    final offsetY = (size.height - contentHeight * scale) / 2 - minY * scale;

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = math.max(stroke.width * scale, 1)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final first = stroke.points.first;
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          Offset(offsetX + first.dx * scale, offsetY + first.dy * scale),
          math.max(stroke.width * scale / 2, 1),
          paint..style = PaintingStyle.fill,
        );
        continue;
      }
      final path = Path()..moveTo(offsetX + first.dx * scale, offsetY + first.dy * scale);
      for (var index = 1; index < stroke.points.length; index += 1) {
        final point = stroke.points[index];
        path.lineTo(offsetX + point.dx * scale, offsetY + point.dy * scale);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => oldDelegate.strokes != strokes;
}

double _number(Object? value) => value is num ? value.toDouble() : 0;

Color _color(Object? value) {
  if (value is! String || !value.startsWith('#')) {
    return const Color(0xFF1A1D2E);
  }
  final hex = value.substring(1);
  final body = hex.length == 3
      ? hex.split('').map((part) => '$part$part').join()
      : hex.length == 6
          ? hex
          : '';
  final parsed = int.tryParse(body, radix: 16);
  if (parsed == null) {
    return const Color(0xFF1A1D2E);
  }
  return Color(0xFF000000 | parsed);
}
