import 'package:flutter/material.dart';

/// Web v2: `platform/src/trainers/math/number-composition/missing-slot.tsx`
class MissingSlot extends StatefulWidget {
  const MissingSlot({
    super.key,
    required this.size,
    required this.isFilled,
    required this.isShaking,
    required this.acceptDrops,
    this.onAccept,
    this.child,
  });

  final double size;
  final bool isFilled;
  final bool isShaking;
  final bool acceptDrops;
  final ValueChanged<int>? onAccept;
  final Widget? child;

  @override
  State<MissingSlot> createState() => MissingSlotState();
}

class MissingSlotState extends State<MissingSlot>
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

    if (widget.isShaking) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(MissingSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isShaking && widget.isShaking) {
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
    final borderColor = widget.isFilled
        ? const Color(0xCC4ADE80)
        : const Color(0xCC818CF8);
    final backgroundColor = widget.isFilled
        ? const Color(0x4D22C55E)
        : const Color(0x80FFFFFF);

    Widget slot = AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeOffset.value, 0),
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
            style: BorderStyle.solid,
          ),
        ),
        child: widget.isFilled
            ? Center(child: widget.child)
            : Center(
                child: Container(
                  width: widget.size * 0.38,
                  height: widget.size * 0.18 * 0.5,
                  decoration: BoxDecoration(
                    color: const Color(0xB3818CF8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
      ),
    );

    if (!widget.acceptDrops || widget.onAccept == null) {
      return slot;
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => !widget.isFilled,
      onAccept: widget.onAccept,
      builder: (context, candidate, rejected) {
        final isHighlighted = candidate.isNotEmpty;
        if (!isHighlighted) {
          return slot;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x334F46E5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: slot,
        );
      },
    );
  }
}
