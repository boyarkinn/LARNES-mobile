import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_scene.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_model.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_sizes.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Web v2: `platform/src/trainers/math/apple-count-show/component.tsx`
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

    return TrainerScene(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sceneWidth = appleSceneWidth(constraints.maxWidth);
          final sceneHeight = appleSceneMaxHeight(constraints.maxHeight);
          final bottomPadding = appleSceneBottomPadding(constraints.maxHeight);

          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding),
              child: SizedBox(
                width: sceneWidth,
                height: sceneHeight,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: AppleCountScene(
                    appleCount: appleCount,
                    sceneKey: _sceneKey,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
