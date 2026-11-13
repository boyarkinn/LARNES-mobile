import 'package:flutter/material.dart';

class TrainerResultComparison extends StatelessWidget {
  const TrainerResultComparison({
    super.key,
    required this.first,
    required this.last,
    required this.firstLabel,
    required this.lastLabel,
  });
  final int first, last;
  final String firstLabel, lastLabel;
  Widget _score(int value, String label, {required bool finalScore}) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        height: 164,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(
          color: finalScore ? const Color(0xFFFFFBEB) : const Color(0xE6FFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            width: 2,
            color: finalScore
                ? const Color(0xFFFCD34D)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: finalScore
                  ? const Color(0x33CA8A04)
                  : const Color(0x1A334155),
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: finalScore
                    ? const Color(0xFF78350F)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$value',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 64,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: finalScore
                      ? const Color(0xFF451A03)
                      : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
      if (finalScore && last > first)
        Positioned(
          top: -10,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              '↑ +${last - first}',
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          Expanded(child: _score(first, firstLabel, finalScore: false)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '→',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
          Expanded(child: _score(last, lastLabel, finalScore: true)),
        ],
      ),
    ),
  );
}
