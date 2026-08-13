import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Web A: фейерверки от поля ответа.
class AnswerFireworksBurst extends StatefulWidget {
  const AnswerFireworksBurst({
    super.key,
    required this.burstKey,
    required this.child,
  });

  final int burstKey;
  final Widget child;

  @override
  State<AnswerFireworksBurst> createState() => _AnswerFireworksBurstState();
}

class _AnswerFireworksBurstState extends State<AnswerFireworksBurst>
    with SingleTickerProviderStateMixin {
  static const _colors = <Color>[
    Color(0xFF2B59C3),
    Color(0xFFFBBF24),
    Color(0xFFF97316),
    Color(0xFF059669),
    Color(0xFFEC4899),
    Color(0xFFFFFFFF),
  ];

  late final AnimationController _controller;
  List<_Rocket> _rockets = const [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(AnswerFireworksBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.burstKey != oldWidget.burstKey && widget.burstKey > 0) {
      _armBurst();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _armBurst() {
    final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disable) {
      return;
    }

    final random = math.Random();
    _rockets = List.generate(5, (rocket) {
      final color = _colors[rocket % _colors.length];
      final sparks = List.generate(14, (i) {
        final angle = (math.pi * 2 * i) / 14 + random.nextDouble() * 0.2;
        return _Spark(
          angle: angle,
          distance: 28 + random.nextDouble() * 42,
          color: _colors[(i + rocket) % _colors.length],
          size: 3.5 + random.nextDouble() * 3.5,
        );
      });
      return _Rocket(
        xFactor: (rocket - 2) / 2.4,
        peakFactor: 0.55 + random.nextDouble() * 0.25,
        riseEnd: 0.28 + rocket * 0.03,
        color: color,
        sparks: sparks,
      );
    });

    _controller.forward(from: 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: -140,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (!_controller.isAnimating && _controller.value == 0) {
                  return const SizedBox.shrink();
                }
                return CustomPaint(
                  painter: _FireworksPainter(
                    progress: _controller.value,
                    rockets: _rockets,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Rocket {
  const _Rocket({
    required this.xFactor,
    required this.peakFactor,
    required this.riseEnd,
    required this.color,
    required this.sparks,
  });

  final double xFactor;
  final double peakFactor;
  final double riseEnd;
  final Color color;
  final List<_Spark> sparks;
}

class _Spark {
  const _Spark({
    required this.angle,
    required this.distance,
    required this.color,
    required this.size,
  });

  final double angle;
  final double distance;
  final Color color;
  final double size;
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter({
    required this.progress,
    required this.rockets,
  });

  final double progress;
  final List<_Rocket> rockets;

  @override
  void paint(Canvas canvas, Size size) {
    if (rockets.isEmpty) {
      return;
    }

    final origin = Offset(size.width / 2, size.height - 36);

    for (final rocket in rockets) {
      final start = Offset(origin.dx + rocket.xFactor * (size.width * 0.35), origin.dy);
      final peak = Offset(start.dx, size.height * (1 - rocket.peakFactor));

      if (progress <= rocket.riseEnd) {
        final t = (progress / rocket.riseEnd).clamp(0.0, 1.0);
        final eased = Curves.easeOut.transform(t);
        final pos = Offset.lerp(start, peak, eased)!;
        final paint = Paint()
          ..color = rocket.color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(pos, 3.2, paint);
        continue;
      }

      final explodeT = ((progress - rocket.riseEnd) / (1 - rocket.riseEnd))
          .clamp(0.0, 1.0);
      final eased = Curves.easeOut.transform(explodeT);
      for (final spark in rocket.sparks) {
        final dx = math.cos(spark.angle) * spark.distance * eased;
        final dy = math.sin(spark.angle) * spark.distance * eased;
        final opacity = (1 - explodeT).clamp(0.0, 1.0);
        final paint = Paint()
          ..color = spark.color.withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
        canvas.drawCircle(
          Offset(peak.dx + dx, peak.dy + dy),
          spark.size * (1 - explodeT * 0.55),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.rockets != rockets;
  }
}
