import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';

const _slotPendingColor = Color(0xFFCBD5E1);

/// Web: `platform/src/trainers/reading/letter-place-in-word/gap-word-row.tsx`
class GapWordRow extends StatefulWidget {
  const GapWordRow({
    super.key,
    required this.after,
    required this.before,
    required this.filledColor,
    required this.filledLetter,
    required this.isAwaitingPlacement,
    required this.onSlotClick,
    required this.slotKey,
    required this.wrongFlash,
  });

  final String after;
  final String before;
  final Color? filledColor;
  final String? filledLetter;
  final bool isAwaitingPlacement;
  final VoidCallback onSlotClick;
  final GlobalKey slotKey;
  final bool wrongFlash;

  @override
  State<GapWordRow> createState() => _GapWordRowState();
}

class _GapWordRowState extends State<GapWordRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(GapWordRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.wrongFlash && widget.wrongFlash) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.onest(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1F2937),
      height: 1.1,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        if (widget.before.isNotEmpty)
          Text(widget.before, style: textStyle),
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeOffset.value, 0),
              child: child,
            );
          },
          child: _GapSlot(
            filledColor: widget.filledColor,
            filledLetter: widget.filledLetter,
            isAwaitingPlacement: widget.isAwaitingPlacement,
            onSlotClick: widget.onSlotClick,
            slotKey: widget.slotKey,
            wrongFlash: widget.wrongFlash,
          ),
        ),
        if (widget.after.isNotEmpty)
          Text(widget.after, style: textStyle),
      ],
    );
  }
}

class _GapSlot extends StatelessWidget {
  const _GapSlot({
    required this.filledColor,
    required this.filledLetter,
    required this.isAwaitingPlacement,
    required this.onSlotClick,
    required this.slotKey,
    required this.wrongFlash,
  });

  final Color? filledColor;
  final String? filledLetter;
  final bool isAwaitingPlacement;
  final VoidCallback onSlotClick;
  final GlobalKey slotKey;
  final bool wrongFlash;

  @override
  Widget build(BuildContext context) {
    final isFilled = filledLetter != null;
    final borderColor = isFilled
        ? const Color(0xCCE5E7EB)
        : wrongFlash
            ? const Color(0xFFF87171)
            : isAwaitingPlacement
                ? ParentColors.shell
                : _slotPendingColor;
    final backgroundColor = isFilled
        ? Colors.white.withValues(alpha: 0.8)
        : wrongFlash
            ? const Color(0xCCFEF2F2)
            : isAwaitingPlacement
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.6);

    return Material(
      key: slotKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: isFilled ? null : onSlotClick,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: isFilled
              ? Text(
                  filledLetter!,
                  style: GoogleFonts.onest(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: filledColor ?? const Color(0xFF1F2937),
                    height: 1,
                  ),
                )
              : Container(
                  width: 18,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _slotPendingColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
        ),
      ),
    );
  }
}
