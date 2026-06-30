import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_layout.dart';

enum DigitChipState { normal, found, wrong }

class DigitFieldScene extends StatelessWidget {
  const DigitFieldScene({
    super.key,
    required this.digits,
    required this.disabled,
    required this.foundIds,
    required this.onTap,
    required this.wrongId,
  });

  final List<PlacedDigit> digits;
  final bool disabled;
  final Set<String> foundIds;
  final ValueChanged<String> onTap;
  final String? wrongId;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 5 / 4,
      child: Container(
        constraints: const BoxConstraints(minHeight: 280),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCCF5F3FF), Colors.white],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDE9FE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final digit in digits)
                  Positioned(
                    left: digit.xPercent / 100 * constraints.maxWidth - 24,
                    top: digit.yPercent / 100 * constraints.maxHeight - 24,
                    child: _DigitChip(
                      key: ValueKey(digit.id),
                      digit: digit,
                      disabled: disabled,
                      state: foundIds.contains(digit.id)
                          ? DigitChipState.found
                          : wrongId == digit.id
                              ? DigitChipState.wrong
                              : DigitChipState.normal,
                      onTap: () => onTap(digit.id),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DigitChip extends StatefulWidget {
  const _DigitChip({
    super.key,
    required this.digit,
    required this.disabled,
    required this.state,
    required this.onTap,
  });

  final PlacedDigit digit;
  final bool disabled;
  final DigitChipState state;
  final VoidCallback onTap;

  @override
  State<_DigitChip> createState() => _DigitChipState();
}

class _DigitChipState extends State<_DigitChip>
    with SingleTickerProviderStateMixin {
  static const _chipSize = 48.0;

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

    if (widget.state == DigitChipState.wrong) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(_DigitChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != DigitChipState.wrong &&
        widget.state == DigitChipState.wrong) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Color get _textColor {
    switch (widget.state) {
      case DigitChipState.wrong:
        return const Color(0xFFDC2626);
      case DigitChipState.found:
        return const Color(0xFF16A34A);
      case DigitChipState.normal:
        return const Color(0xFF1F2937);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFound = widget.state == DigitChipState.found;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeOffset.value, 0),
          child: child,
        );
      },
      child: AnimatedScale(
        scale: isFound ? 1.12 : 1.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.disabled || isFound ? null : widget.onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: _chipSize,
              height: _chipSize,
              child: Center(
                child: Text(
                  '${widget.digit.digit}',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
