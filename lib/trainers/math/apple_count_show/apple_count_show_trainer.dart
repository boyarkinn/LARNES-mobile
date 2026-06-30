import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_scene.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

class AppleCountShowTrainer extends StatefulWidget {
  const AppleCountShowTrainer({
    super.key,
    required this.params,
  });

  final Map<String, dynamic> params;

  @override
  State<AppleCountShowTrainer> createState() => _AppleCountShowTrainerState();
}

class _AppleCountShowTrainerState extends State<AppleCountShowTrainer> {
  late String _sceneKey;

  @override
  void initState() {
    super.initState();
    _sceneKey = _buildSceneKey();
  }

  @override
  void didUpdateWidget(AppleCountShowTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params['digit'] != widget.params['digit']) {
      setState(() => _sceneKey = _buildSceneKey());
    }
  }

  String _buildSceneKey() {
    final digit = widget.params['digit'];
    return '$digit-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    final digit = normalizeDigit(widget.params['digit'] as num? ?? 0);
    final appleCount = digitToAppleCount(digit);

    return TrainerShell(
      tone: TrainerShellTone.rose,
      minHeight: 240,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$digit',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE11D48),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          AppleCountScene(
            appleCount: appleCount,
            sceneKey: _sceneKey,
          ),
          if (appleCount == 0) ...[
            const SizedBox(height: 12),
            const Text(
              'В корзинке пусто',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xCCE11D48),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
