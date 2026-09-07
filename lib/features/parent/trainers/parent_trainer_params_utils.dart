import 'package:larnes_mobile/features/admin/models/trainer_play.dart';

String stringifyTrainerFormValue(dynamic value) {
  if (value is List) {
    return value.join(',');
  }
  return value?.toString() ?? '';
}

Map<String, String> mergeStoredParamsIntoFormValues(
  TrainerPlayConfig config,
  Map<String, dynamic> params,
) {
  final values = config.initialValues();

  if (config.trainerKey == 'flashcard-digit-match') {
    if (params.containsKey('pairCount')) {
      values['pairCount'] = stringifyTrainerFormValue(params['pairCount']);
    } else if (params['values'] is List) {
      values['pairCount'] = '${(params['values'] as List).length}';
    }
    if (params.containsKey('rounds')) {
      values['rounds'] = stringifyTrainerFormValue(params['rounds']);
    }
    if (params.containsKey('targetMode')) {
      values['targetMode'] = stringifyTrainerFormValue(params['targetMode']);
    }
    if (params.containsKey('totalRods')) {
      values['totalRods'] = stringifyTrainerFormValue(params['totalRods']);
    }
    return values;
  }

  if (config.trainerKey == 'letter-grid-match') {
    if (params.containsKey('practiceLetters')) {
      values['practiceLetters'] = stringifyTrainerFormValue(params['practiceLetters']);
    }
    if (params.containsKey('gridSize')) {
      values['digit'] = stringifyTrainerFormValue(params['gridSize']);
    }
    if (params.containsKey('filledCount')) {
      values['entityCount'] = stringifyTrainerFormValue(params['filledCount']);
    }
    if (params.containsKey('letterCase')) {
      values['letterCase'] = stringifyTrainerFormValue(params['letterCase']);
    }
    return values;
  }

  if (config.trainerKey == 'topic-chain-flash' || config.trainerKey == 'topic-chain-table') {
    if (params.containsKey('topicId')) {
      values['chainTopicId'] = stringifyTrainerFormValue(params['topicId']);
    }
  }

  if (config.trainerKey == 'fly-track') {
    if (params.containsKey('gridSize')) {
      values['digit'] = stringifyTrainerFormValue(params['gridSize']);
    }
  }

  for (final entry in params.entries) {
    if (values.containsKey(entry.key)) {
      values[entry.key] = stringifyTrainerFormValue(entry.value);
    }
  }

  return values;
}
