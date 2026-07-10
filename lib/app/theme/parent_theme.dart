import 'package:flutter/material.dart';

/// Morning Desk v4 — design tokens parent-зоны.
/// Эталон: platform/src/app/themes/parent.css
class ParentColors {
  const ParentColors._();

  static const parchment = Color(0xFFF0EBE3);
  static const parchmentDeep = Color(0xFFE4DDD2);
  static const ink = Color(0xFF1A1D2E);
  static const inkMuted = Color(0xFF4A5068);
  static const surface = Color(0xFFFFFCF8);
  static const shell = Color(0xFF2B59C3);
  static const shellDeep = Color(0xFF1E429F);
  static const shellSoft = Color(0xFFDCE8FF);
  static const line = Color(0xFFD5CFC4);
  static const lineHover = Color(0xFFC9C2B8);
  static const shadow = Color.fromRGBO(26, 29, 46, 0.09);
  static const focusRing = Color.fromRGBO(43, 89, 195, 0.32);
}

class ParentRadii {
  const ParentRadii._();

  /// 1.125rem @ 16px root
  static const card = 18.0;
}

class ParentMotion {
  const ParentMotion._();

  static const duration = Duration(milliseconds: 180);
  static const tapDuration = Duration(milliseconds: 100);
  static const curve = Cubic(0.22, 1, 0.36, 1);
}

/// Размеры name-tag карточки ребёнка (web `.parent-child-card`, mobile column).
class ParentChildCardMetrics {
  const ParentChildCardMetrics._();

  static const minHeight = 102.0; // 6.375rem
  static const bandHeight = 42.0; // 2.625rem
  static const innerOverlap = 18.0; // 1.125rem
  static const innerHorizontalPadding = 17.0; // 1.0625rem
  static const innerBottomPadding = 17.0;
  static const avatarRingSize = 57.0; // 3.5625rem
  static const avatarImageSize = 35.0;
  static const rowGap = 13.0; // 0.8125rem
  static const metaTopPadding = 20.0; // 1.25rem
  static const nameLineGap = 5.0;
  static const footerTopPadding = 13.0;
  static const pickerListGap = 14.0; // 0.875rem
  static const pickerMaxWidth = 512.0; // 32rem
  static const addCardIconSize = 46.0; // 2.875rem
  static const addCardGap = 11.0; // 0.6875rem

  /// Fredoka 19 / height 1.1 in [ChildProfileCard].
  static const nameLineHeight = 19.0 * 1.1;

  /// Age pill: padding 5+5, 12pt label, box-shadow offset 2 (+ font rounding).
  static const agePillHeight = 29.0;

  /// Subpixel headroom (Google Fonts metrics vs formula).
  static const pickerListLayoutSlack = 4.0;

  /// Picker list: child + add + study hub cards (band + 2 name lines + age).
  static double get pickerListCardHeight {
    final metaHeight = metaTopPadding + nameLineHeight * 2 + nameLineGap;
    final rowHeight = metaHeight > avatarRingSize ? metaHeight : avatarRingSize;
    return bandHeight +
        innerBottomPadding +
        rowHeight +
        footerTopPadding +
        agePillHeight +
        pickerListLayoutSlack;
  }
}

/// Размеры hub-карточки (web `.parent-study-hub-card`, mobile column).
class ParentStudyHubCardMetrics {
  const ParentStudyHubCardMetrics._();

  static const minHeight = 102.0;
  static const bandHeight = 32.0; // 2rem
  static const innerPadding = EdgeInsets.fromLTRB(20, 12, 20, 18);
  static const contentGap = 10.0; // 0.625rem
  static const iconRingSize = 48.0; // 3rem
  static const iconImageSize = 22.0; // 1.375rem
}

/// Tap feedback web `.parent-card-base:active` — scale(0.98).
class ParentScaleTap extends StatefulWidget {
  const ParentScaleTap({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  State<ParentScaleTap> createState() => _ParentScaleTapState();
}

class _ParentScaleTapState extends State<ParentScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: ParentMotion.tapDuration,
        curve: ParentMotion.curve,
        child: widget.child,
      ),
    );
  }
}

/// Фон parent-зоны: пергамент + radial wash + линовка (web `.parent-shell`).
BoxDecoration parentParchmentDecoration() {
  return const BoxDecoration(color: ParentColors.parchment);
}

class ParentParchmentBackground extends StatelessWidget {
  const ParentParchmentBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: ParentParchmentPainter()),
        child,
      ],
    );
  }
}

class ParentParchmentPainter extends CustomPainter {
  const ParentParchmentPainter();

  static const _lineSpacing = 34.0; // 2.125rem

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final rect = Offset.zero & size;

    canvas.drawRect(rect, Paint()..color = ParentColors.parchment);

    _drawRadialWash(
      canvas,
      rect,
      center: Offset(size.width * 0.1, 0),
      radius: size.width * 0.7,
      color: const Color.fromRGBO(43, 89, 195, 0.07),
    );
    _drawRadialWash(
      canvas,
      rect,
      center: Offset(size.width * 0.9, size.height * 0.05),
      radius: size.width * 0.6,
      color: const Color.fromRGBO(255, 107, 53, 0.08),
    );

    final linePaint = Paint()
      ..color = const Color.fromRGBO(43, 89, 195, 0.045)
      ..strokeWidth = 1;

    for (var y = _lineSpacing; y < size.height; y += _lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  void _drawRadialWash(
    Canvas canvas,
    Rect rect, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            (center.dx / rect.width) * 2 - 1,
            (center.dy / rect.height) * 2 - 1,
          ),
          radius: radius / rect.shortestSide,
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0, 0.55],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Карточка parent-зоны (web `.parent-card-base`).
BoxDecoration parentCardDecoration() {
  return BoxDecoration(
    color: ParentColors.surface,
    borderRadius: BorderRadius.circular(ParentRadii.card),
    border: Border.all(color: ParentColors.line),
    boxShadow: const [
      BoxShadow(
        color: ParentColors.shadow,
        blurRadius: 18,
        offset: Offset(0, 5),
      ),
    ],
  );
}

/// Карточка «Добавить ребёнка» (web `.parent-add-card`) — фаза 5 подключит dashed border.
BoxDecoration parentAddCardDecoration() {
  return BoxDecoration(
    color: ParentColors.surface.withValues(alpha: 0.65),
    borderRadius: BorderRadius.circular(ParentRadii.card),
    border: Border.all(
      color: ParentColors.shell.withValues(alpha: 0.45),
      width: 2,
      strokeAlign: BorderSide.strokeAlignInside,
    ),
  );
}
