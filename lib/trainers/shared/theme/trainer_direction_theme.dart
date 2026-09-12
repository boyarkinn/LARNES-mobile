import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';

@immutable
class TrainerDirectionTheme {
  const TrainerDirectionTheme({
    required this.base,
    required this.deep,
    required this.soft,
    required this.glow,
    required this.secondary,
    required this.surface,
  });

  final Color base;
  final Color deep;
  final Color soft;
  final Color glow;
  final Color secondary;
  final Color surface;
}

const trainerDirectionThemes = <TrainerDirection, TrainerDirectionTheme>{
  TrainerDirection.math: TrainerDirectionTheme(
    base: Color(0xFFE4573D),
    deep: Color(0xFFC84331),
    soft: Color(0x3DF0A33A),
    glow: Color(0x52E4573D),
    secondary: Color(0xFFF0A33A),
    surface: Color(0xFFFFF3ED),
  ),
  TrainerDirection.reading: TrainerDirectionTheme(
    base: Color(0xFF249B73),
    deep: Color(0xFF187B5A),
    soft: Color(0x3D8BDCB2),
    glow: Color(0x47249B73),
    secondary: Color(0xFF8BDCB2),
    surface: Color(0xFFF0FBF3),
  ),
  TrainerDirection.mental: TrainerDirectionTheme(
    base: Color(0xFF7759D6),
    deep: Color(0xFF5F43BA),
    soft: Color(0x42A992EF),
    glow: Color(0x577759D6),
    secondary: Color(0xFF5BC4D6),
    surface: Color(0xFFF4F0FF),
  ),
  TrainerDirection.intel: TrainerDirectionTheme(
    base: Color(0xFF2F66D0),
    deep: Color(0xFF173B73),
    soft: Color(0x33F2B84B),
    glow: Color(0x4D2F66D0),
    secondary: Color(0xFFF2B84B),
    surface: Color(0xFFEEF6FF),
  ),
};

class TrainerDirectionThemeScope extends InheritedWidget {
  const TrainerDirectionThemeScope({
    super.key,
    required this.direction,
    required super.child,
  });

  final TrainerDirection direction;

  TrainerDirectionTheme get theme => trainerDirectionThemes[direction]!;

  static TrainerDirectionThemeScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No TrainerDirectionThemeScope found in context.');
    return scope!;
  }

  static TrainerDirectionThemeScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TrainerDirectionThemeScope>();
  }

  @override
  bool updateShouldNotify(TrainerDirectionThemeScope oldWidget) {
    return direction != oldWidget.direction;
  }
}

class TrainerDirectionStage extends StatefulWidget {
  const TrainerDirectionStage({super.key, required this.child});

  final Widget child;

  @override
  State<TrainerDirectionStage> createState() => _TrainerDirectionStageState();
}

class _TrainerDirectionStageState extends State<TrainerDirectionStage> {
  static const _ambientDuration = Duration(seconds: 26);

  bool _ambientForward = true;

  void _reverseAmbient() {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    setState(() => _ambientForward = !_ambientForward);
  }

  @override
  Widget build(BuildContext context) {
    final scope = TrainerDirectionThemeScope.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return ColoredBox(
      color: scope.theme.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: CustomPaint(
              key: const ValueKey('trainer-direction-stage-static'),
              painter: _TrainerDirectionStaticPainter(
                direction: scope.direction,
                theme: scope.theme,
              ),
              isComplex: true,
            ),
          ),
          IgnorePointer(
            child: disableAnimations
                ? CustomPaint(
                    key: const ValueKey('trainer-direction-stage-ambient'),
                    painter: _TrainerDirectionAmbientPainter(
                      direction: scope.direction,
                      progress: 0.5,
                      theme: scope.theme,
                    ),
                  )
                : TweenAnimationBuilder<double>(
                    key: const ValueKey('trainer-direction-stage-ambient'),
                    tween: Tween<double>(
                      begin: 0,
                      end: _ambientForward ? 1 : 0,
                    ),
                    duration: _ambientDuration,
                    curve: Curves.easeInOut,
                    onEnd: _reverseAmbient,
                    builder: (context, progress, child) {
                      return CustomPaint(
                        painter: _TrainerDirectionAmbientPainter(
                          direction: scope.direction,
                          progress: progress,
                          theme: scope.theme,
                        ),
                      );
                    },
                  ),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

class _TrainerDirectionStaticPainter extends CustomPainter {
  const _TrainerDirectionStaticPainter({
    required this.direction,
    required this.theme,
  });

  final TrainerDirection direction;
  final TrainerDirectionTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              theme.soft.withValues(alpha: 0.08),
              theme.soft.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.88, size.height * 0.08),
              radius: size.shortestSide * 0.64,
            ),
          );
    canvas.drawRect(bounds, glowPaint);

    final secondGlowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              (direction == TrainerDirection.mental
                      ? theme.secondary
                      : theme.glow)
                  .withValues(alpha: 0.06),
              (direction == TrainerDirection.mental
                      ? theme.secondary
                      : theme.glow)
                  .withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.08, size.height * 0.9),
              radius: size.shortestSide * 0.7,
            ),
          );
    canvas.drawRect(bounds, secondGlowPaint);

    if (direction == TrainerDirection.mental) {
      canvas.drawRect(
        bounds,
        Paint()
          ..shader =
              const RadialGradient(
                colors: [Color(0xB3FFFFFF), Color(0x00FFFFFF)],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(size.width * 0.5, size.height * 0.48),
                  radius: size.shortestSide * 0.58,
                ),
              ),
      );
      final routeWidth = (size.shortestSide * 0.065).clamp(24.0, 44.0);
      canvas.drawPath(
        _mentalLeftRoute(size),
        Paint()
          ..color = theme.base.withValues(alpha: 0.075)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = routeWidth,
      );
      canvas.drawPath(
        _mentalRightRoute(size),
        Paint()
          ..color = theme.secondary.withValues(alpha: 0.065)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = routeWidth,
      );
    }

    if (direction == TrainerDirection.intel) {
      canvas.drawRect(
        bounds,
        Paint()
          ..shader =
              const RadialGradient(
                colors: [Color(0xC2FFFFFF), Color(0x00FFFFFF)],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(size.width * 0.5, size.height * 0.48),
                  radius: size.shortestSide * 0.6,
                ),
              ),
      );
      for (final route in _intelRoutes(size)) {
        canvas.drawPath(
          route,
          Paint()
            ..color = theme.base.withValues(alpha: 0.045)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = 18,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TrainerDirectionStaticPainter oldDelegate) {
    return direction != oldDelegate.direction || theme != oldDelegate.theme;
  }
}

class _TrainerDirectionAmbientPainter extends CustomPainter {
  const _TrainerDirectionAmbientPainter({
    required this.direction,
    required this.progress,
    required this.theme,
  });

  final TrainerDirection direction;
  final double progress;
  final TrainerDirectionTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (direction == TrainerDirection.mental) {
      _drawMentalRoutes(canvas, size);
      return;
    }
    if (direction == TrainerDirection.intel) {
      _drawIntelNetwork(canvas, size);
      return;
    }

    final drift = Curves.easeInOut.transform(progress) * 2 - 1;
    final shortest = size.shortestSide;

    _drawGlow(
      canvas,
      center: Offset(
        size.width * 0.03 + drift * 12,
        size.height * 0.08 + drift * 7,
      ),
      radius: shortest * 0.48,
      color: theme.base.withValues(alpha: 0.055),
    );
    _drawGlow(
      canvas,
      center: Offset(
        size.width * 0.98 - drift * 14,
        size.height * 0.92 - drift * 8,
      ),
      radius: shortest * 0.55,
      color: theme.soft.withValues(alpha: 0.07),
    );
    _drawGlow(
      canvas,
      center: Offset(
        size.width * 1.02 - drift * 9,
        size.height * 0.3 + drift * 11,
      ),
      radius: shortest * 0.34,
      color: theme.glow.withValues(alpha: 0.04),
    );

    _drawParticle(
      canvas,
      Offset(size.width * 0.07 + drift * 7, size.height * 0.18 + drift * 9),
      1,
    );
    _drawParticle(
      canvas,
      Offset(size.width * 0.92 - drift * 8, size.height * 0.86 - drift * 6),
      0.88,
    );
    _drawParticle(
      canvas,
      Offset(size.width * 0.95 - drift * 5, size.height * 0.38 + drift * 7),
      0.64,
    );
  }

  void _drawMentalRoutes(Canvas canvas, Size size) {
    final eased = Curves.easeInOut.transform(progress);
    final leftRoute = _mentalLeftRoute(size);
    final rightRoute = _mentalRightRoute(size);

    _drawDashedRoute(
      canvas,
      leftRoute,
      color: theme.base.withValues(alpha: 0.24),
      offset: progress * 72,
      dash: 4,
      gap: 16,
    );
    _drawDashedRoute(
      canvas,
      rightRoute,
      color: theme.secondary.withValues(alpha: 0.23),
      offset: -progress * 84,
      dash: 3,
      gap: 18,
    );
    _drawRouteNode(
      canvas,
      leftRoute,
      progress: eased,
      color: theme.base,
      radius: 5,
    );
    _drawRouteNode(
      canvas,
      rightRoute,
      progress: 1 - eased,
      color: theme.secondary,
      radius: 4,
    );
  }

  void _drawIntelNetwork(Canvas canvas, Size size) {
    final routes = _intelRoutes(size);
    for (var index = 0; index < routes.length; index++) {
      _drawDashedRoute(
        canvas,
        routes[index],
        color: (index.isEven ? theme.base : theme.secondary).withValues(
          alpha: 0.2,
        ),
        offset: (index.isEven ? progress : -progress) * (66 + index * 7),
        dash: index.isEven ? 3 : 2,
        gap: index.isEven ? 13 : 16,
      );
    }
    _drawRouteNode(
      canvas,
      routes.first,
      progress: Curves.easeInOut.transform(progress),
      color: theme.base,
      radius: 4.5,
    );
    _drawRouteNode(
      canvas,
      routes.last,
      progress: 1 - Curves.easeInOut.transform(progress),
      color: theme.secondary,
      radius: 4,
    );
  }

  void _drawDashedRoute(
    Canvas canvas,
    Path path, {
    required Color color,
    required double offset,
    required double dash,
    required double gap,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    final cycle = dash + gap;

    for (final metric in path.computeMetrics()) {
      var distance = -(offset % cycle);
      while (distance < metric.length) {
        final start = distance.clamp(0.0, metric.length);
        final end = (distance + dash).clamp(0.0, metric.length);
        if (end > start) {
          canvas.drawPath(metric.extractPath(start, end), paint);
        }
        distance += cycle;
      }
    }
  }

  void _drawRouteNode(
    Canvas canvas,
    Path path, {
    required double progress,
    required Color color,
    required double radius,
  }) {
    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) {
      return;
    }
    final metric = metrics.first;
    final tangent = metric.getTangentForOffset(metric.length * progress);
    if (tangent == null) {
      return;
    }

    canvas.drawCircle(
      tangent.position,
      radius * 2.6,
      Paint()..color = color.withValues(alpha: 0.08),
    );
    canvas.drawCircle(
      tangent.position,
      radius,
      Paint()..color = color.withValues(alpha: 0.8),
    );
  }

  void _drawGlow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(bounds),
    );
  }

  void _drawParticle(Canvas canvas, Offset center, double scale) {
    canvas.drawCircle(
      center,
      8 * scale,
      Paint()..color = theme.base.withValues(alpha: 0.035),
    );
    canvas.drawCircle(
      center,
      3 * scale,
      Paint()..color = theme.base.withValues(alpha: 0.15),
    );
  }

  @override
  bool shouldRepaint(_TrainerDirectionAmbientPainter oldDelegate) {
    return direction != oldDelegate.direction ||
        progress != oldDelegate.progress ||
        theme != oldDelegate.theme;
  }
}

Path _mentalLeftRoute(Size size) {
  return Path()
    ..moveTo(-size.width * 0.025, size.height * 0.77)
    ..cubicTo(
      size.width * 0.09,
      size.height * 0.64,
      size.width * 0.02,
      size.height * 0.35,
      size.width * 0.15,
      size.height * 0.145,
    )
    ..cubicTo(
      size.width * 0.195,
      size.height * 0.073,
      size.width * 0.19,
      0,
      size.width * 0.215,
      -size.height * 0.06,
    );
}

Path _mentalRightRoute(Size size) {
  return Path()
    ..moveTo(size.width * 1.035, size.height * 0.175)
    ..cubicTo(
      size.width * 0.88,
      size.height * 0.21,
      size.width * 0.95,
      size.height * 0.475,
      size.width * 0.845,
      size.height * 0.595,
    )
    ..cubicTo(
      size.width * 0.775,
      size.height * 0.675,
      size.width * 0.86,
      size.height * 0.875,
      size.width * 0.735,
      size.height * 1.06,
    );
}

List<Path> _intelRoutes(Size size) {
  return [
    Path()
      ..moveTo(-size.width * 0.035, size.height * 0.19)
      ..lineTo(size.width * 0.08, size.height * 0.19)
      ..lineTo(size.width * 0.135, size.height * 0.28)
      ..lineTo(size.width * 0.225, size.height * 0.28)
      ..lineTo(size.width * 0.275, size.height * 0.37),
    Path()
      ..moveTo(-size.width * 0.03, size.height * 0.83)
      ..lineTo(size.width * 0.07, size.height * 0.83)
      ..lineTo(size.width * 0.12, size.height * 0.75)
      ..lineTo(size.width * 0.12, size.height * 0.66)
      ..lineTo(size.width * 0.2, size.height * 0.66),
    Path()
      ..moveTo(size.width * 1.035, size.height * 0.17)
      ..lineTo(size.width * 0.925, size.height * 0.17)
      ..lineTo(size.width * 0.87, size.height * 0.26)
      ..lineTo(size.width * 0.87, size.height * 0.37)
      ..lineTo(size.width * 0.79, size.height * 0.37),
    Path()
      ..moveTo(size.width * 1.03, size.height * 0.84)
      ..lineTo(size.width * 0.92, size.height * 0.84)
      ..lineTo(size.width * 0.865, size.height * 0.75)
      ..lineTo(size.width * 0.77, size.height * 0.75)
      ..lineTo(size.width * 0.725, size.height * 0.67),
  ];
}
