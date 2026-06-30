import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/triple_scene.dart';

class DotsDigitAbacusTrainer extends StatelessWidget {
  const DotsDigitAbacusTrainer({
    super.key,
    required this.params,
  });

  final Map<String, dynamic> params;

  @override
  Widget build(BuildContext context) {
    final totalRods = params['totalRods'] as int? ?? 1;
    final value = params['value'] as int? ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Смотри: столько точек — это число $value — вот оно на абакусе',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 20),
        TripleScene(
          totalRods: totalRods,
          value: value,
        ),
      ],
    );
  }
}
