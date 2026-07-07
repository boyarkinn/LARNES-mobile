import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';

enum AddChildCardVariant {
  list,
  empty,
}

/// Карточка «Добавить ребёнка» на picker.
/// Эталон: platform/src/components/parent/add-child-card.tsx
class AddChildCard extends StatelessWidget {
  const AddChildCard({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = AddChildCardVariant.list,
  });

  final String label;
  final VoidCallback onTap;
  final AddChildCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final card = ParentScaleTap(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: ParentColors.shell.withValues(alpha: 0.45),
          radius: ParentRadii.card,
        ),
        child: Container(
          width: double.infinity,
          height: ParentChildCardMetrics.pickerListCardHeight,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ParentColors.surface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(ParentRadii.card),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              _AddCardIcon(),
              const SizedBox(height: ParentChildCardMetrics.addCardGap),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.onest(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ParentColors.shellDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (variant == AddChildCardVariant.empty) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ParentChildCardMetrics.pickerMaxWidth),
        child: card,
      );
    }

    return card;
  }
}

class _AddCardIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: ParentChildCardMetrics.addCardIconSize,
      height: ParentChildCardMetrics.addCardIconSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ParentColors.shell,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: ParentColors.shellDeep,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '+',
        style: GoogleFonts.fredoka(
          fontSize: 26,
          fontWeight: FontWeight.w500,
          height: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rect);
    const dashWidth = 6.0;
    const dashSpace = 5.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
