import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Kiosk standby tokens — parity web `kiosk-surface.css` (parent landing v3).
class KioskColors {
  const KioskColors._();

  static const porcelain = Color(0xFFF5F7F2);
  static const paper = Color(0xFFFFFEFA);
  static const ink = Color(0xFF12262F);
  static const muted = Color(0xFF62747A);
  static const blue = Color(0xFF345BFF);
  static const blueSoft = Color(0xFFE4E9FF);
  static const green = Color(0xFF1D9B78);
  static const line = Color(0xFFD8E0DC);
  static const shadow = Color(0x1C12262F);
}

class KioskMotion {
  const KioskMotion._();

  static const duration = Duration(milliseconds: 200);
  static const tapDuration = Duration(milliseconds: 120);
  static const curve = Cubic(0.23, 1, 0.32, 1);
}

BoxDecoration kioskHeroDecoration() {
  return const BoxDecoration(color: KioskColors.porcelain);
}

/// Full-bleed hero bg — parity web `.kiosk-surface--hero-bg` (radial washes, not linear).
class KioskHeroBackground extends StatelessWidget {
  const KioskHeroBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: KioskHeroPainter()),
        child,
      ],
    );
  }
}

class KioskHeroPainter extends CustomPainter {
  const KioskHeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = KioskColors.porcelain);

    _drawRadialWash(
      canvas,
      rect,
      center: Offset(size.width * 0.86, size.height * 0.12),
      radius: size.shortestSide * 0.28,
      color: const Color.fromRGBO(52, 91, 255, 0.11),
    );
    _drawRadialWash(
      canvas,
      rect,
      center: Offset(size.width * 0.06, size.height * 0.70),
      radius: size.shortestSide * 0.25,
      color: const Color.fromRGBO(29, 155, 120, 0.08),
    );
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
          stops: const [0, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

BoxDecoration kioskPaperPanelDecoration() {
  return BoxDecoration(
    color: KioskColors.paper,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: KioskColors.line),
    boxShadow: const [
      BoxShadow(
        color: KioskColors.shadow,
        blurRadius: 40,
        offset: Offset(0, 18),
      ),
    ],
  );
}

TextStyle kioskSectionLabelStyle() {
  return const TextStyle(
    color: KioskColors.blue,
    fontFamily: 'monospace',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );
}

/// Web `.kiosk-standby__settings` — chip in the top-right of standby screens.
class KioskStandbySettingsButton extends StatefulWidget {
  const KioskStandbySettingsButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<KioskStandbySettingsButton> createState() =>
      _KioskStandbySettingsButtonState();
}

class _KioskStandbySettingsButtonState extends State<KioskStandbySettingsButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: KioskMotion.tapDuration,
          curve: KioskMotion.curve,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: KioskColors.paper.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: KioskColors.line.withValues(alpha: 0.95),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F12262F),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: KioskColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted header for kiosk sub-pages (settings).
class KioskPageHeader extends StatelessWidget {
  const KioskPageHeader({
    super.key,
    required this.title,
    this.onBackPressed,
  });

  final String title;
  final VoidCallback? onBackPressed;

  static const _sideSlotWidth = 48.0;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: KioskColors.paper.withValues(alpha: 0.88),
            border: const Border(bottom: BorderSide(color: KioskColors.line)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 12),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  SizedBox(
                    width: _sideSlotWidth,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _KioskHeaderBackButton(
                        onPressed: onBackPressed ?? () => context.pop(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: KioskColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: _sideSlotWidth),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KioskHeaderBackButton extends StatefulWidget {
  const _KioskHeaderBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_KioskHeaderBackButton> createState() => _KioskHeaderBackButtonState();
}

class _KioskHeaderBackButtonState extends State<_KioskHeaderBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: KioskMotion.tapDuration,
          curve: KioskMotion.curve,
          child: const Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: KioskColors.blue,
          ),
        ),
      ),
    );
  }
}

/// Web `.kiosk-standby__cta` — primary pill action.
class KioskPrimaryButton extends StatefulWidget {
  const KioskPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<KioskPrimaryButton> createState() => _KioskPrimaryButtonState();
}

class _KioskPrimaryButtonState extends State<KioskPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed && enabled ? 0.98 : 1,
          duration: KioskMotion.tapDuration,
          curve: KioskMotion.curve,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.55,
            duration: KioskMotion.duration,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: KioskColors.blue,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3D345BFF),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary outline action on paper panels (sign out).
class KioskSecondaryButton extends StatefulWidget {
  const KioskSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<KioskSecondaryButton> createState() => _KioskSecondaryButtonState();
}

class _KioskSecondaryButtonState extends State<KioskSecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed && enabled ? 0.98 : 1,
          duration: KioskMotion.tapDuration,
          curve: KioskMotion.curve,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.55,
            duration: KioskMotion.duration,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: KioskColors.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: KioskColors.line),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: KioskColors.ink,
                          ),
                        )
                      : Text(
                          widget.label,
                          style: const TextStyle(
                            color: KioskColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool?> showKioskConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelLabel,
  required String confirmLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: KioskColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: KioskColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: KioskColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                color: KioskColors.muted,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: KioskSecondaryButton(
                    label: cancelLabel,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: KioskPrimaryButton(
                    label: confirmLabel,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
