import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

class FlashCard extends StatelessWidget {
  const FlashCard({
    super.key,
    required this.value,
    required this.totalRods,
    this.connected = false,
    this.disabled = false,
    this.onPointerDown,
  });

  final int value;
  final int totalRods;
  final bool connected;
  final bool disabled;
  final void Function(PointerDownEvent event)? onPointerDown;

  @override
  Widget build(BuildContext context) {
    final borderColor = connected
        ? const Color(0xFF6EE7B7)
        : disabled
            ? const Color(0xFFE5E7EB)
            : const Color(0xFFFED7AA);

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: disabled || connected ? null : onPointerDown,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: connected ? 0.7 : disabled ? 0.4 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF7ED),
                Colors.white,
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              height: 112,
              child: IgnorePointer(
                child: AbacusWidget(
                  animate: false,
                  rods: numberToAbacus(value, totalRods),
                  totalRods: totalRods,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
