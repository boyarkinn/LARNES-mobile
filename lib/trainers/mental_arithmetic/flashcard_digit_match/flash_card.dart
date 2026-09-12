import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

/// Web v2: `platform/src/trainers/mental-arithmetic/flashcard-digit-match/flash-card.tsx`
class FlashCard extends StatelessWidget {
  const FlashCard({
    super.key,
    required this.value,
    required this.totalRods,
    required this.abacusHeight,
    required this.activeBeadColor,
    this.connected = false,
    this.disabled = false,
    this.selected = false,
    this.onPointerDown,
    this.onPointerUp,
  });

  final int value;
  final int totalRods;
  final double abacusHeight;
  final Color activeBeadColor;
  final bool connected;
  final bool disabled;
  final bool selected;
  final void Function(PointerDownEvent event)? onPointerDown;
  final void Function(PointerUpEvent event)? onPointerUp;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: disabled || connected ? null : onPointerDown,
      onPointerUp: disabled || connected ? null : onPointerUp,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: connected
            ? 0.85
            : disabled
            ? 0.4
            : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: connected
                  ? const Color(0xFF34D399)
                  : selected
                  ? const Color(0xFFE45B4E)
                  : disabled
                  ? const Color(0xFFE5E7EB)
                  : const Color(0x337759D6),
              width: 2,
            ),
            color: const Color(0x80FFFFFF),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0x1FE45B4E)
                    : const Color(0x1A7759D6),
                blurRadius: selected ? 30 : 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  height: abacusHeight,
                  child: IgnorePointer(
                    child: AbacusWidget(
                      activeBeadColor: activeBeadColor,
                      animate: false,
                      rods: numberToAbacus(value, totalRods),
                      totalRods: totalRods,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -9,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: connected
                          ? const Color(0xFF10B981)
                          : selected
                          ? const Color(0xFFE45B4E)
                          : const Color(0xFF7759D6),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: selected
                          ? const [
                              BoxShadow(
                                color: Color(0x33E45B4E),
                                blurRadius: 10,
                                spreadRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
              if (connected)
                const Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(0xFF10B981),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
