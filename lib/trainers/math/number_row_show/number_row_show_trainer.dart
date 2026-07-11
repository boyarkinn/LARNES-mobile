import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_scene.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_model.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_sizes.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Web v2: `platform/src/trainers/math/number-row-show/component.tsx`
class NumberRowShowTrainer extends StatefulWidget {
  const NumberRowShowTrainer({
    super.key,
    required this.params,
  });

  final Map<String, dynamic> params;

  @override
  State<NumberRowShowTrainer> createState() => _NumberRowShowTrainerState();
}

class _NumberRowShowTrainerState extends State<NumberRowShowTrainer> {
  late String _sceneKey;

  @override
  void initState() {
    super.initState();
    _sceneKey = _buildSceneKey();
  }

  @override
  void didUpdateWidget(NumberRowShowTrainer oldWidget) {
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
    final studyDigit = normalizeStudyDigit(widget.params['digit'] as num? ?? 0);

    return TrainerScene(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sceneWidth = numberRowSceneWidth(constraints.maxWidth);
          final sceneHeight = numberRowSceneMaxHeight(constraints.maxHeight);

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: sceneWidth,
                height: sceneHeight,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: NumberRowScene(
                    studyDigit: studyDigit,
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
