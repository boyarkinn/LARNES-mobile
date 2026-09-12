import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_sizes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/triple_scene_layout.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/dot_layout.dart';

/// Web: `triple-scene.tsx` visibility contract.
class TripleSceneVisibility {
  const TripleSceneVisibility({
    this.abacusPulseActive = false,
    this.digitPulseActive = false,
    this.showAbacus = false,
    this.showAbacusValue = false,
    this.showAbacusEquals = false,
    this.showDigit = false,
    this.showDigitEquals = false,
    this.showDots = false,
    this.visibleDotCount = 0,
  });

  final bool abacusPulseActive;
  final bool digitPulseActive;
  final bool showAbacus;
  final bool showAbacusValue;
  final bool showAbacusEquals;
  final bool showDigit;
  final bool showDigitEquals;
  final bool showDots;
  final int visibleDotCount;

  TripleSceneVisibility copyWith({
    bool? abacusPulseActive,
    bool? digitPulseActive,
    bool? showAbacus,
    bool? showAbacusValue,
    bool? showAbacusEquals,
    bool? showDigit,
    bool? showDigitEquals,
    bool? showDots,
    int? visibleDotCount,
  }) {
    return TripleSceneVisibility(
      abacusPulseActive: abacusPulseActive ?? this.abacusPulseActive,
      digitPulseActive: digitPulseActive ?? this.digitPulseActive,
      showAbacus: showAbacus ?? this.showAbacus,
      showAbacusValue: showAbacusValue ?? this.showAbacusValue,
      showAbacusEquals: showAbacusEquals ?? this.showAbacusEquals,
      showDigit: showDigit ?? this.showDigit,
      showDigitEquals: showDigitEquals ?? this.showDigitEquals,
      showDots: showDots ?? this.showDots,
      visibleDotCount: visibleDotCount ?? this.visibleDotCount,
    );
  }
}

/// Web v2: `platform/src/trainers/mental-arithmetic/dots-digit-abacus/triple-scene.tsx`
class TripleScene extends StatelessWidget {
  const TripleScene({super.key, required this.value, required this.visibility});

  final int value;
  final TripleSceneVisibility visibility;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = computeTripleSceneLayout(
          viewportWidth: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
          dotCount: value,
        );
        final rods = numberToAbacus(value, kDotsDigitAbacusTotalRods);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: _SceneBlock(
                    visible: visibility.showDots,
                    pulseActive: false,
                    child: DotsDigitAbacusAnimatedDots(
                      count: value,
                      width: layout.dotFrameWidth,
                      height: layout.dotFrameHeight,
                      visibleCount: visibility.visibleDotCount,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Center(
                child: _SceneBlock(
                  visible: visibility.showDigitEquals,
                  pulseActive: false,
                  child: const _EqualsSign(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: _SceneBlock(
                    visible: visibility.showDigit,
                    pulseActive: visibility.digitPulseActive,
                    child: _digit(layout.digitCardSize, layout.digitFontSize),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Center(
                child: _SceneBlock(
                  visible: visibility.showAbacusEquals,
                  pulseActive: false,
                  child: const _EqualsSign(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: _SceneBlock(
                    visible: visibility.showAbacus,
                    pulseActive: visibility.abacusPulseActive,
                    enterFromSide: true,
                    child: _abacusCard(
                      context,
                      layout.abacusWidth,
                      layout.abacusHeight,
                      visibility.showAbacusValue
                          ? rods
                          : emptyRods(kDotsDigitAbacusTotalRods),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _digit(double cardSize, double fontSize) {
    return SizedBox(
      key: const Key('triple-digit'),
      width: cardSize,
      height: cardSize,
      child: DotsDigitAbacusDrawnDigit(value: value),
    );
  }

  Widget _abacusCard(
    BuildContext context,
    double width,
    double height,
    List<RodState> rods,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: AbacusWidget(
        activeBeadColor: const Color(kDotsDigitAbacusObjectColor),
        animate: !MediaQuery.disableAnimationsOf(context),
        rods: rods,
        totalRods: kDotsDigitAbacusTotalRods,
      ),
    );
  }
}

class _EqualsSign extends StatelessWidget {
  const _EqualsSign();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('triple-equals-sign'),
      width: 34,
      height: 28,
      child: DotsDigitAbacusDrawnEquals(
        color: const Color(kDotsDigitAbacusObjectColor),
      ),
    );
  }
}

class _SceneBlock extends StatefulWidget {
  const _SceneBlock({
    required this.visible,
    required this.pulseActive,
    required this.child,
    this.enterFromSide = false,
  });

  final bool visible;
  final bool pulseActive;
  final Widget child;
  final bool enterFromSide;

  @override
  State<_SceneBlock> createState() => _SceneBlockState();
}

class _SceneBlockState extends State<_SceneBlock>
    with SingleTickerProviderStateMixin {
  static const _popDurationMs = 400;
  static const _popScaleBegin = 0.92;
  static const _popOffsetY = 10.0;

  late final AnimationController _pulseController;
  var _revealed = false;
  var _enterProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: dotsDigitAbacusPulseCycleMs),
    );
    _revealed = widget.visible;
    if (_revealed) {
      _enterProgress = 1;
    }
    _syncPulse();
  }

  @override
  void didUpdateWidget(_SceneBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.visible && widget.visible) {
      _revealed = true;
      _runEnterAnimation();
    }
    _syncPulse();
  }

  void _runEnterAnimation() {
    _enterProgress = 0;
    const steps = 16;
    var step = 0;
    void tick() {
      if (!mounted) {
        return;
      }
      step += 1;
      setState(() {
        _enterProgress = Curves.easeOutBack.transform(step / steps);
      });
      if (step < steps) {
        Future<void>.delayed(
          Duration(milliseconds: _popDurationMs ~/ steps),
          tick,
        );
      }
    }

    tick();
  }

  void _syncPulse() {
    if (widget.pulseActive) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return const SizedBox.shrink();
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final progress = reduceMotion ? 1.0 : _enterProgress;
    final opacity = progress;
    final offsetY = _popOffsetY * (1 - progress);
    final offsetX = widget.enterFromSide ? 96 * (1 - progress) : 0.0;
    final rotation = widget.enterFromSide
        ? (7 * (1 - progress)) * math.pi / 180
        : 0.0;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final animatedPulseScale = widget.pulseActive && !reduceMotion
            ? 1 + _pulseController.value * 0.04
            : 1.0;
        final animatedScale =
            (_popScaleBegin + (1 - _popScaleBegin) * progress) *
            animatedPulseScale;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(scale: animatedScale, child: child),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class DotsDigitAbacusAnimatedDots extends StatefulWidget {
  const DotsDigitAbacusAnimatedDots({
    super.key,
    required this.count,
    required this.height,
    required this.visibleCount,
    required this.width,
  });

  final int count;
  final double height;
  final int visibleCount;
  final double width;

  @override
  State<DotsDigitAbacusAnimatedDots> createState() =>
      _DotsDigitAbacusAnimatedDotsState();
}

class _DotsDigitAbacusAnimatedDotsState
    extends State<DotsDigitAbacusAnimatedDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _arrivingIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
      value: 1,
    )..addListener(_repaint);
  }

  @override
  void didUpdateWidget(DotsDigitAbacusAnimatedDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visibleCount > oldWidget.visibleCount) {
      _arrivingIndex = widget.visibleCount - 1;
      _controller.forward(from: 0);
    }
  }

  void _repaint() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    const color = Color(kDotsDigitAbacusObjectColor);
    return SizedBox(
      key: const Key('triple-dots'),
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _TravelingDotsPainter(
          arrivingIndex: reduceMotion ? null : _arrivingIndex,
          color: color,
          count: widget.count,
          progress: reduceMotion
              ? 1
              : Curves.easeInOutCubicEmphasized.transform(_controller.value),
          visibleCount: widget.visibleCount,
        ),
      ),
    );
  }
}

class _TravelingDotsPainter extends CustomPainter {
  const _TravelingDotsPainter({
    required this.arrivingIndex,
    required this.color,
    required this.count,
    required this.progress,
    required this.visibleCount,
  });

  final int? arrivingIndex;
  final Color color;
  final int count;
  final double progress;
  final int visibleCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (count == 0) {
      final paint = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(
        size.center(Offset.zero),
        size.shortestSide * 0.22,
        paint,
      );
      return;
    }

    final positions = getDotPositionsForValue(count);
    final radius = getDotRadius(count);
    for (
      var index = 0;
      index < math.min(visibleCount, positions.length);
      index++
    ) {
      final target = Offset(
        positions[index].x * size.width,
        positions[index].y * size.height,
      );
      if (arrivingIndex == index && progress < 1) {
        final from = Offset(
          index.isEven ? -radius * 5 : size.width + radius * 5,
          index % 3 == 0 ? -radius * 5 : size.height + radius * 5,
        );
        final center = Offset.lerp(from, target, progress)!;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate((index.isEven ? -0.45 : 0.45) * (1 - progress));
        canvas.scale(0.72 + progress * 0.28);
        canvas.drawCircle(Offset.zero, radius, Paint()..color = color);
        canvas.restore();
      } else {
        canvas.drawCircle(target, radius, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(_TravelingDotsPainter oldDelegate) {
    return oldDelegate.arrivingIndex != arrivingIndex ||
        oldDelegate.color != color ||
        oldDelegate.count != count ||
        oldDelegate.progress != progress ||
        oldDelegate.visibleCount != visibleCount;
  }
}

class DotsDigitAbacusDrawnEquals extends StatelessWidget {
  const DotsDigitAbacusDrawnEquals({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: reduceMotion ? 0 : 480),
      curve: Curves.easeInOutCubicEmphasized,
      builder: (context, progress, child) => CustomPaint(
        painter: _EqualsPainter(color: color, progress: progress),
      ),
    );
  }
}

class _EqualsPainter extends CustomPainter {
  const _EqualsPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    final length = size.width * progress;
    canvas.drawLine(
      Offset(0, size.height * 0.34),
      Offset(length, size.height * 0.34),
      paint,
    );
    final second = ((progress - 0.18) / 0.82).clamp(0.0, 1.0);
    canvas.drawLine(
      Offset(0, size.height * 0.68),
      Offset(size.width * second, size.height * 0.68),
      paint,
    );
  }

  @override
  bool shouldRepaint(_EqualsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}

class DotsDigitAbacusDrawnDigit extends StatelessWidget {
  const DotsDigitAbacusDrawnDigit({
    super.key,
    required this.value,
    this.color = const Color(kDotsDigitAbacusObjectColor),
  });

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: reduceMotion ? 0 : 780),
      curve: Curves.easeInOutCubicEmphasized,
      builder: (context, progress, child) => CustomPaint(
        painter: _DigitStrokePainter(
          color: color,
          progress: progress,
          value: value,
        ),
      ),
    );
  }
}

class _DigitStrokePainter extends CustomPainter {
  const _DigitStrokePainter({
    required this.color,
    required this.progress,
    required this.value,
  });

  final Color color;
  final double progress;
  final int value;

  static const _segmentsByDigit = <List<int>>[
    [0, 1, 2, 4, 5, 6],
    [2, 5],
    [0, 2, 3, 4, 6],
    [0, 2, 3, 5, 6],
    [1, 2, 3, 5],
    [0, 1, 3, 5, 6],
    [0, 1, 3, 4, 5, 6],
    [0, 2, 5],
    [0, 1, 2, 3, 4, 5, 6],
    [0, 1, 2, 3, 5, 6],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final margin = size.shortestSide * 0.18;
    final left = margin;
    final right = size.width - margin;
    final top = margin * 0.55;
    final middle = size.height * 0.5;
    final bottom = size.height - margin * 0.55;
    final segments = <Path>[
      Path()
        ..moveTo(left, top)
        ..lineTo(right, top),
      Path()
        ..moveTo(left, top)
        ..lineTo(left, middle),
      Path()
        ..moveTo(right, top)
        ..lineTo(right, middle),
      Path()
        ..moveTo(left, middle)
        ..lineTo(right, middle),
      Path()
        ..moveTo(left, middle)
        ..lineTo(left, bottom),
      Path()
        ..moveTo(right, middle)
        ..lineTo(right, bottom),
      Path()
        ..moveTo(left, bottom)
        ..lineTo(right, bottom),
    ];
    final active = _segmentsByDigit[value.clamp(0, 9)];
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(5, size.shortestSide * 0.085);

    for (var order = 0; order < active.length; order++) {
      final local = (progress * active.length - order).clamp(0.0, 1.0);
      final path = segments[active[order]];
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * local), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DigitStrokePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.progress != progress ||
      oldDelegate.value != value;
}
