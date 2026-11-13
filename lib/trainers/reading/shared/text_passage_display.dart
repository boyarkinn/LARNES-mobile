import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'passage.dart';

/// The same TextPainter supplies wrapping, line metrics and paint coordinates.
class TextPassageDisplay extends StatelessWidget {
  const TextPassageDisplay({
    super.key,
    required this.units,
    this.hiddenOrder = 0,
    this.visibleHalf,
    this.upsideDown = false,
    this.hiddenTextOffset,
    this.focusTextOffset,
    this.scrollController,
  });
  final List<VanishUnit> units;
  final int hiddenOrder;
  final String? visibleHalf;
  final bool upsideDown;
  final int? hiddenTextOffset;
  final int? focusTextOffset;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.min(896.0, constraints.maxWidth);
      final fontSize = upsideDown
          ? 32.0
          : (width / 24).clamp(22.0, 42.0).toDouble();
      var offset = 0;
      final hidden = units.map((unit) {
        offset += unit.grapheme.length;
        return hiddenTextOffset != null
            ? offset <= hiddenTextOffset!
            : unit.order <= hiddenOrder;
      }).toList();
      final painter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: upsideDown ? TextAlign.center : TextAlign.start,
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: upsideDown ? 1.25 : 1.45,
            color: const Color(0xFF20352D),
          ),
          children: [
            for (var index = 0; index < units.length; index++)
              TextSpan(
                text: units[index].grapheme,
                style: TextStyle(
                  color: hidden[index]
                      ? const Color(0x0020352D)
                      : const Color(0xFF20352D),
                ),
              ),
          ],
        ),
      )..layout(maxWidth: width);
      if (focusTextOffset != null && scrollController != null) {
        final caret = painter.getOffsetForCaret(
          TextPosition(
            offset: focusTextOffset!.clamp(
              0,
              units.fold<int>(0, (sum, unit) => sum + unit.grapheme.length),
            ),
          ),
          Rect.zero,
        );
        final viewportHeight = constraints.maxHeight;
        final target = (caret.dy - viewportHeight / 3)
            .clamp(0.0, math.max(0.0, painter.height - viewportHeight))
            .toDouble();
        final reduced = MediaQuery.disableAnimationsOf(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final controller = scrollController!;
          if (!controller.hasClients) return;
          if (caret.dy < controller.offset ||
              caret.dy > controller.offset + viewportHeight * 0.8) {
            if (reduced) {
              controller.jumpTo(target);
            } else {
              controller.animateTo(
                target,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
              );
            }
          }
        });
      }
      return SingleChildScrollView(
        controller: scrollController,
        reverse: upsideDown,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: SizedBox(
              width: width,
              height: painter.height,
              child: CustomPaint(
                painter: _PassagePainter(painter, visibleHalf, upsideDown),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _PassagePainter extends CustomPainter {
  _PassagePainter(this.text, this.visibleHalf, this.upsideDown);
  final TextPainter text;
  final String? visibleHalf;
  final bool upsideDown;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (upsideDown) {
      canvas.translate(size.width, size.height);
      canvas.rotate(math.pi);
    }
    if (visibleHalf != null) {
      final path = Path();
      for (final line in text.computeLineMetrics()) {
        final height = line.ascent + line.descent;
        final top =
            line.baseline -
            line.ascent +
            (visibleHalf == 'bottom' ? height * 0.35 : 0);
        path.addRect(Rect.fromLTWH(0, top, size.width, height * 0.65));
      }
      canvas.clipPath(path);
    }
    text.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PassagePainter oldDelegate) => true;
}
