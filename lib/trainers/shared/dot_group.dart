import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/dot_layout.dart';

enum DotGroupSize {
  sm,
  md,
  lg,

  /// Как в `dots-digit-abacus`: 112×112 для ≤9 точек, иначе 160×160.
  auto,
}

enum DotGroupTone {
  orange,
  indigo,
}

/// Web: `DOT_REVEAL_INTERVAL_MS` in dots-digit-abacus/dot-reveal.ts
const _dotRevealIntervalMs = 500;

class DotGroup extends StatefulWidget {
  const DotGroup({
    super.key,
    required this.count,
    this.size = DotGroupSize.auto,
    this.tone = DotGroupTone.orange,
    this.revealProgressively = false,
    this.frameWidth,
    this.frameHeight,
  });

  final int count;
  final DotGroupSize size;
  final DotGroupTone tone;
  final bool revealProgressively;
  final double? frameWidth;
  final double? frameHeight;

  @override
  State<DotGroup> createState() => _DotGroupState();
}

class _DotGroupState extends State<DotGroup> {
  int _visibleCount = 0;
  final List<Timer> _revealTimers = [];

  @override
  void initState() {
    super.initState();
    _scheduleReveal();
  }

  @override
  void didUpdateWidget(DotGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count ||
        oldWidget.revealProgressively != widget.revealProgressively) {
      _cancelRevealTimers();
      _scheduleReveal();
    }
  }

  @override
  void dispose() {
    _cancelRevealTimers();
    super.dispose();
  }

  void _cancelRevealTimers() {
    for (final timer in _revealTimers) {
      timer.cancel();
    }
    _revealTimers.clear();
  }

  void _scheduleReveal() {
    if (!widget.revealProgressively) {
      setState(() => _visibleCount = widget.count);
      return;
    }

    setState(() => _visibleCount = widget.count > 0 ? 1 : 0);

    for (var index = 2; index <= widget.count; index++) {
      final timer = Timer(
        Duration(milliseconds: (index - 1) * _dotRevealIntervalMs),
        () {
          if (!mounted) {
            return;
          }
          setState(() => _visibleCount = index);
        },
      );
      _revealTimers.add(timer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _sizeSpec(widget.size, widget.count);
    final colors = _colorsForTone(widget.tone);
    final width = widget.frameWidth ?? spec.frameSize;
    final height = widget.frameHeight ?? spec.frameSize;
    final positions = getDotPositionsForValue(widget.count);
    final visiblePositions = widget.revealProgressively
        ? positions.take(_visibleCount).toList(growable: false)
        : positions;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _DotGroupPainter(
          positions: visiblePositions,
          dotRadius: spec.dotRadius,
          dotColor: colors.dot,
        ),
      ),
    );
  }

  static _DotGroupSizeSpec _sizeSpec(DotGroupSize size, int count) {
    switch (size) {
      case DotGroupSize.sm:
        return const _DotGroupSizeSpec(frameSize: 56, dotRadius: 5);
      case DotGroupSize.md:
        return const _DotGroupSizeSpec(frameSize: 80, dotRadius: 6);
      case DotGroupSize.lg:
        return const _DotGroupSizeSpec(frameSize: 112, dotRadius: 7);
      case DotGroupSize.auto:
        if (count <= 9) {
          return _DotGroupSizeSpec(
            frameSize: 112,
            dotRadius: getDotRadius(count),
          );
        }
        return _DotGroupSizeSpec(
          frameSize: 160,
          dotRadius: getDotRadius(count),
        );
    }
  }

  static _DotGroupColors _colorsForTone(DotGroupTone tone) {
    switch (tone) {
      case DotGroupTone.orange:
        return const _DotGroupColors(
          border: Color(0xFFFED7AA),
          dot: Color(0xFFF97316),
        );
      case DotGroupTone.indigo:
        return const _DotGroupColors(
          border: Color(0xFFE2E8F0),
          dot: Color(0xFF4F46E5),
        );
    }
  }
}

class _DotGroupSizeSpec {
  const _DotGroupSizeSpec({
    required this.frameSize,
    required this.dotRadius,
  });

  final double frameSize;
  final double dotRadius;
}

class _DotGroupColors {
  const _DotGroupColors({
    required this.border,
    required this.dot,
  });

  final Color border;
  final Color dot;
}

class _DotGroupPainter extends CustomPainter {
  _DotGroupPainter({
    required this.positions,
    required this.dotRadius,
    required this.dotColor,
  });

  final List<DotPosition> positions;
  final double dotRadius;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;

    for (final position in positions) {
      canvas.drawCircle(
        Offset(position.x * size.width, position.y * size.height),
        dotRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DotGroupPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.dotColor != dotColor;
  }
}
