import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/audio/speech_alignment.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_result_scope.dart';
import 'package:larnes_mobile/trainers/reading/shared/text_passage_model.dart';
import 'package:larnes_mobile/trainers/reading/shared/text_passage_play.dart';
import 'package:larnes_mobile/trainers/catalog/validate_trainer_params_result.dart';

ValidateTrainerParamsResult validateReadingTugParams(
  Map<String, dynamic> params,
) {
  final error = validateTextPassageParams(params);
  if (error != null) return ValidateTrainerParamsResult.failure(error);
  final rate = double.tryParse('${params['narratorRate'] ?? 1}');
  if (rate == null || !rate.isFinite || rate < 0.5 || rate > 2)
    return const ValidateTrainerParamsResult.failure(
      'Укажите скорость диктора от 0,5 до 2.',
    );
  return ValidateTrainerParamsResult.success({
    'source': 'bank',
    'contentBank': params['contentBank'],
    'narratorRate': rate,
    'disappearance': params['disappearance'] == 'on' ? 'on' : 'off',
  });
}

class ReadingTugTrainer extends StatelessWidget {
  const ReadingTugTrainer({super.key, required this.params, this.onComplete});
  final Map<String, dynamic> params;
  final VoidCallback? onComplete;
  @override
  Widget build(BuildContext context) {
    final raw = readTrainerRuntimeSnapshot('reading-tug', params);
    final audio = raw?['audio'];
    if (raw == null ||
        audio is! Map ||
        raw['text'] is! String ||
        audio['text'] != raw['text'] ||
        audio['durationMs'] is! int)
      return const Center(
        child: Text('Выберите текст с готовой аудиозаписью.'),
      );
    final text = raw['text'] as String;
    final alignment = SpeechAlignment.fromJson(
      audio['alignment'],
      text,
      audio['durationMs'] as int,
    );
    final narration = NarratedPassage(
      semanticKey: '${audio['semanticKey']}',
      audioVersionId: '${audio['versionId']}',
      durationMs: audio['durationMs'] as int,
      rate: (raw['narratorRate'] as num? ?? 1).toDouble(),
      alignment: alignment,
    );
    if (raw['disappearance'] == 'on' && alignment == null)
      return const Center(child: Text('У записи нет временных меток.'));
    return TextPassagePlay(
      key: ValueKey((
        TrainerResultScope.maybeOf(context)?.storageKey,
        narration.audioVersionId,
      )),
      trainerKey: 'reading-tug',
      narration: narration,
      plan: TextPassagePlan(
        text: text,
        letterPauseMs: 180,
        disappearance: raw['disappearance'] == 'on',
      ),
      instruction: 'Читай вслух вместе с диктором и старайся успевать за ним.',
      onComplete: onComplete,
    );
  }
}
