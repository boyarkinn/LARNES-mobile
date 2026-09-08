import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_sizes.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

/// Web: `platform/src/trainers/mental-arithmetic/dots-digit-abacus/abacus-match-card.tsx`
class AbacusMatchCard extends StatelessWidget {
  const AbacusMatchCard({
    super.key,
    required this.value,
    this.connected = false,
    this.shake = false,
    this.width,
    this.height,
    this.totalRods = kDotsDigitAbacusTotalRods,
  });

  final int value;
  final bool connected;
  final bool shake;
  final double? width;
  final double? height;
  final int totalRods;

  @override
  Widget build(BuildContext context) {
    final rods = numberToAbacus(value, totalRods);
    final borderColor = shake
        ? const Color(0xFFFCA5A5)
        : connected
        ? const Color(0xFF6EE7B7)
        : const Color(0xFFFED7AA);

    final card = Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF7ED), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(
        height: height,
        child: AbacusWidget(
          activeBeadColor: const Color(kDotsDigitAbacusActiveBeadColor),
          rods: rods,
          totalRods: totalRods,
        ),
      ),
    );

    if (!shake) {
      return Opacity(opacity: connected ? 0.8 : 1, child: card);
    }

    return _ShakeWrapper(active: shake, child: card);
  }
}

class _ShakeWrapper extends StatefulWidget {
  const _ShakeWrapper({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_ShakeWrapper> createState() => _ShakeWrapperState();
}

class _ShakeWrapperState extends State<_ShakeWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    if (widget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(_ShakeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = t <= 0.2
            ? -8 * (t / 0.2)
            : t <= 0.4
            ? -8 + 16 * ((t - 0.2) / 0.2)
            : t <= 0.6
            ? 8 - 13 * ((t - 0.4) / 0.2)
            : t <= 0.8
            ? -5 + 10 * ((t - 0.6) / 0.2)
            : 5 * (1 - ((t - 0.8) / 0.2));

        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
