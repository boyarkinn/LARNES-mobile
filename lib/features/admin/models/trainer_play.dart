import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flashcard_digit_match_model.dart';
import 'package:larnes_mobile/trainers/shared/param_coerce.dart';

enum TrainerPlayFieldType { number, text, select }

class TrainerPlayFieldOption {
  const TrainerPlayFieldOption({
    required this.value,
    this.label,
    this.labelKey,
  });

  factory TrainerPlayFieldOption.fromJson(Map<String, dynamic> json) {
    return TrainerPlayFieldOption(
      value: json['value'] as String,
      label: json['label'] as String?,
      labelKey: json['labelKey'] as String?,
    );
  }

  final String value;
  final String? label;
  final String? labelKey;
}

class TrainerPlayFieldShowWhen {
  const TrainerPlayFieldShowWhen({required this.field, required this.equals});

  factory TrainerPlayFieldShowWhen.fromJson(Map<String, dynamic> json) {
    return TrainerPlayFieldShowWhen(
      field: json['field'] as String,
      equals: json['equals'] as String,
    );
  }

  final String field;
  final String equals;
}

class TrainerPlayField {
  const TrainerPlayField({
    required this.key,
    required this.labelKey,
    required this.type,
    this.min,
    this.max,
    this.maxLength,
    this.placeholder,
    this.options = const [],
    this.showWhen,
  });

  factory TrainerPlayField.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List<dynamic>? ?? const [];
    final showWhenJson = json['showWhen'] as Map?;

    return TrainerPlayField(
      key: json['key'] as String,
      labelKey: json['labelKey'] as String,
      type: _parseType(json['type'] as String?),
      min: _parseOptionalNum(json['min']),
      max: _parseOptionalNum(json['max']),
      maxLength: json['maxLength'] as int?,
      placeholder: json['placeholder'] as String?,
      options: optionsJson
          .map((item) => TrainerPlayFieldOption.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      showWhen: showWhenJson == null
          ? null
          : TrainerPlayFieldShowWhen.fromJson(Map<String, dynamic>.from(showWhenJson)),
    );
  }

  final String key;
  final String labelKey;
  final TrainerPlayFieldType type;
  final num? min;
  final num? max;
  final int? maxLength;
  final String? placeholder;
  final List<TrainerPlayFieldOption> options;
  final TrainerPlayFieldShowWhen? showWhen;

  bool isVisible(Map<String, String> values) {
    final condition = showWhen;
    if (condition == null) {
      return true;
    }
    return values[condition.field] == condition.equals;
  }
}

class TrainerPlayConfig {
  const TrainerPlayConfig({
    required this.trainerKey,
    required this.title,
    required this.direction,
    required this.isInteractive,
    required this.defaultParams,
    required this.fields,
  });

  factory TrainerPlayConfig.fromJson(Map<String, dynamic> json) {
    final fieldsJson = json['fields'] as List<dynamic>? ?? const [];
    final defaultsJson = json['defaultParams'] as Map? ?? const {};

    return TrainerPlayConfig(
      trainerKey: json['trainerKey'] as String,
      title: json['title'] as String,
      direction: json['direction'] as String? ?? 'mental',
      isInteractive: json['isInteractive'] as bool? ?? false,
      defaultParams: Map<String, dynamic>.from(defaultsJson),
      fields: fieldsJson
          .map((item) => TrainerPlayField.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  final String trainerKey;
  final String title;
  final String direction;
  final bool isInteractive;
  final Map<String, dynamic> defaultParams;
  final List<TrainerPlayField> fields;

  Map<String, String> initialValues() {
    return {
      for (final entry in defaultParams.entries)
        entry.key: _stringifyValue(entry.value),
    };
  }

  static String _stringifyValue(dynamic value) {
    if (value is List) {
      return value.join(',');
    }
    return value?.toString() ?? '';
  }
}

class TrainerPlaySession {
  const TrainerPlaySession({required this.playUrl, required this.expiresAt});

  factory TrainerPlaySession.fromJson(Map<String, dynamic> json) {
    return TrainerPlaySession(
      playUrl: json['playUrl'] as String,
      expiresAt: json['expiresAt'] as String,
    );
  }

  final String playUrl;
  final String expiresAt;
}

class AdminTrainerPlayLaunch {
  const AdminTrainerPlayLaunch({
    required this.trainerKey,
    required this.title,
    required this.params,
  });

  final String trainerKey;
  final String title;
  final Map<String, dynamic> params;
}

TrainerPlayFieldType _parseType(String? raw) {
  switch (raw) {
    case 'select':
      return TrainerPlayFieldType.select;
    case 'text':
      return TrainerPlayFieldType.text;
    case 'number':
    default:
      return TrainerPlayFieldType.number;
  }
}

num? _parseOptionalNum(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value;
  }
  return num.tryParse(value.toString());
}

Map<String, dynamic> buildPlayParamsPayload(
  TrainerPlayConfig config,
  Map<String, String> values,
) {
  if (config.trainerKey == 'letter-grid-match') {
    return {
      'practiceLetters': values['practiceLetters'],
      'gridSize': coerceInt(values['digit']) ?? 3,
      'filledCount': coerceInt(values['entityCount']) ?? 4,
      'letterCase': values['letterCase'],
    };
  }

  if (config.trainerKey == 'flashcard-digit-match') {
    final totalRods = coerceInt(values['totalRods']);
    return {
      'totalRods': totalRods ?? 1,
      'values': parseMatchValuesFromInput(
        pairCount: values['pairCount'],
        value0: values['value0'],
        value1: values['value1'],
        value2: values['value2'],
        value3: values['value3'],
      ),
    };
  }

  if (config.trainerKey == 'topic-chain-flash') {
    return {
      'actionCount': coerceInt(values['actionCount']) ?? 5,
      'exampleCount': coerceInt(values['exampleCount']) ?? 1,
      'stepPauseSec': coerceDouble(values['stepPauseSec']) ?? 1,
      'topicId': values['chainTopicId'] ?? values['topicId'] ?? 'simple-1',
    };
  }

  if (config.trainerKey == 'topic-chain-table') {
    return {
      'actionCount': coerceInt(values['actionCount']) ?? 4,
      'exampleCount': coerceInt(values['exampleCount']) ?? 5,
      'topicId': values['chainTopicId'] ?? values['topicId'] ?? 'simple-1',
    };
  }

  final payload = <String, dynamic>{};
  for (final field in config.fields) {
    if (!field.isVisible(values)) {
      continue;
    }
    final raw = values[field.key];
    if (raw == null || raw.isEmpty) {
      continue;
    }
    if (field.type == TrainerPlayFieldType.number) {
      payload[field.key] = num.tryParse(raw) ?? raw;
    } else {
      payload[field.key] = raw;
    }
  }
  return payload;
}
