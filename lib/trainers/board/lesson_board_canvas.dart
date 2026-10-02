import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/board/lesson_board_scene.dart';

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

class LessonBoardCanvas extends StatefulWidget {
  const LessonBoardCanvas({
    required this.elements,
    this.canDraw = false,
    this.color = const Color(0xFF1E1E1E),
    this.eraser = false,
    this.onErase,
    this.onStroke,
    super.key,
  });

  final List<Map<String, dynamic>> elements;
  final bool canDraw;
  final Color color;
  final bool eraser;
  final void Function(BoardPoint at, double radius)? onErase;
  final void Function(List<BoardPoint> points)? onStroke;

  @override
  State<LessonBoardCanvas> createState() => _LessonBoardCanvasState();
}

class _LessonBoardCanvasState extends State<LessonBoardCanvas> {
  List<Offset> _active = const [];
  _BoardView? _frozen;

  @override
  void didUpdateWidget(covariant LessonBoardCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.canDraw && _active.isNotEmpty) {
      _active = const [];
      _frozen = null;
    }
  }

  void _start(DragStartDetails details, _BoardView view) {
    final scene = view.toScene(details.localPosition);
    setState(() => _frozen = view);
    if (widget.eraser) {
      widget.onErase?.call(BoardPoint(scene.dx, scene.dy), 18 / view.scale);
      return;
    }
    setState(() => _active = [scene]);
  }

  void _move(DragUpdateDetails details) {
    final view = _frozen;
    if (view == null) {
      return;
    }
    final scene = view.toScene(details.localPosition);
    if (widget.eraser) {
      widget.onErase?.call(BoardPoint(scene.dx, scene.dy), 18 / view.scale);
      return;
    }
    setState(() => _active = [..._active, scene]);
  }

  void _end() {
    final points = _active;
    setState(() {
      _active = const [];
      _frozen = null;
    });
    if (widget.eraser || points.isEmpty) {
      return;
    }
    widget.onStroke?.call([for (final point in points) BoardPoint(point.dx, point.dy)]);
  }

  @override
  Widget build(BuildContext context) {
    final strokes = LessonBoardStroke.fromElements(widget.elements);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final view = _frozen ?? _BoardView.fit(strokes, size);
        final shown = [
          ...strokes,
          if (_active.isNotEmpty)
            LessonBoardStroke(points: _active, color: widget.color, width: 2),
        ];
        final paint = CustomPaint(
          painter: _BoardPainter(shown, view),
          child: const SizedBox.expand(),
        );
        if (!widget.canDraw) {
          return paint;
        }
        return GestureDetector(
          onPanStart: (details) => _start(details, view),
          onPanUpdate: _move,
          onPanEnd: (_) => _end(),
          onPanCancel: _end,
          child: paint,
        );
      },
    );
  }
}

class _BoardView {
  const _BoardView(this.scale, this.offsetX, this.offsetY);

  final double scale;
  final double offsetX;
  final double offsetY;

  Offset toScene(Offset local) => Offset((local.dx - offsetX) / scale, (local.dy - offsetY) / scale);

  static _BoardView fit(List<LessonBoardStroke> strokes, Size size) {
    if (strokes.isEmpty || size.isEmpty) {
      return const _BoardView(1, 0, 0);
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
    return _BoardView(
      scale,
      (size.width - contentWidth * scale) / 2 - minX * scale,
      (size.height - contentHeight * scale) / 2 - minY * scale,
    );
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter(this.strokes, this.view);

  final List<LessonBoardStroke> strokes;
  final _BoardView view;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFFFFF));
    _grid(canvas, size);
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = math.max(stroke.width * view.scale, 1)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final first = stroke.points.first;
      final start = Offset(view.offsetX + first.dx * view.scale, view.offsetY + first.dy * view.scale);
      if (stroke.points.length == 1) {
        canvas.drawCircle(start, math.max(stroke.width * view.scale / 2, 1), paint..style = PaintingStyle.fill);
        continue;
      }
      final path = Path()..moveTo(start.dx, start.dy);
      for (var index = 1; index < stroke.points.length; index += 1) {
        final point = stroke.points[index];
        path.lineTo(view.offsetX + point.dx * view.scale, view.offsetY + point.dy * view.scale);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _grid(Canvas canvas, Size size) {
    if (size.isEmpty || view.scale <= 0) {
      return;
    }
    final left = -view.offsetX / view.scale;
    final top = -view.offsetY / view.scale;
    final right = (size.width - view.offsetX) / view.scale;
    final bottom = (size.height - view.offsetY) / view.scale;
    var step = 20.0;
    while ((right - left) / step > 40) {
      step *= 2;
    }
    final paint = Paint()
      ..color = const Color(0xFFE6E6E6)
      ..strokeWidth = 1;
    final startX = (left / step).floor() * step;
    for (var x = startX; x <= right; x += step) {
      final local = view.offsetX + x * view.scale;
      canvas.drawLine(Offset(local, 0), Offset(local, size.height), paint);
    }
    final startY = (top / step).floor() * step;
    for (var y = startY; y <= bottom; y += step) {
      final local = view.offsetY + y * view.scale;
      canvas.drawLine(Offset(0, local), Offset(size.width, local), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
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
