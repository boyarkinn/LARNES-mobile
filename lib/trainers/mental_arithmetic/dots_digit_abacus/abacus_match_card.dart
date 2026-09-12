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
    this.framed = true,
  });

  final int value;
  final bool connected;
  final bool shake;
  final double? width;
  final double? height;
  final int totalRods;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final rods = numberToAbacus(value, totalRods);
    final borderColor = shake
        ? const Color(kDotsDigitAbacusWrongLineColor)
        : connected
        ? const Color(kDotsDigitAbacusLockedLineColor)
        : const Color(0xFFCBD5E1);

    final card = Container(
      width: width,
      padding: EdgeInsets.all(framed ? 8 : 0),
      decoration: BoxDecoration(
        color: !framed
            ? Colors.transparent
            : shake
            ? const Color(0x40FEE2E2)
            : connected
            ? const Color(0x4074E5A0)
            : const Color(0x59F8FAFC),
        borderRadius: BorderRadius.circular(framed ? 16 : 0),
        border: framed ? Border.all(color: borderColor, width: 2) : null,
        boxShadow: framed
            ? const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: SizedBox(
        height: height,
        child: AbacusWidget(
          activeBeadColor: const Color(kDotsDigitAbacusObjectColor),
          rods: rods,
          totalRods: totalRods,
        ),
      ),
    );

    if (!shake || MediaQuery.disableAnimationsOf(context)) {
      return card;
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
