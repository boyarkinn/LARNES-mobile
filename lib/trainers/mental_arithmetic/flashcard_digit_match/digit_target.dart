import 'package:flutter/material.dart';

class DigitTarget extends StatelessWidget {
  const DigitTarget({
    super.key,
    required this.digit,
    this.connected = false,
  });

  final int digit;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: connected
              ? const Color(0xFF6EE7B7)
              : const Color(0xFFC7D2FE),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: Text(
            '$digit',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: connected
                  ? const Color(0xFF059669)
                  : const Color(0xFF4F46E5),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
