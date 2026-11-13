import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';

const readingContentBankLibraryId = '4c65cc30-b447-4eb3-9d83-af7b2c0a72a1';

const readingContentBankTrainerKeys = {
  'letter-first-by-sound',
  'letter-word-link',
  'letter-place-in-word',
  'word-cubes',
  'reading-anagram',
  'reading-shutter',
  'reading-vanish',
  'reading-upside-down',
  'reading-pace-track',
  'reading-noisy-text',
  'reading-pointer',
  'reading-blocks',
  'reading-tree',
  'reading-flash',
  'reading-fixation',
  'reading-diagonal',
  'reading-reread',
  'reading-echo',
  'reading-phrases',
  'reading-find-span',
  'reading-word-sprint',
  'reading-cloze',
  'reading-story-order',
  'reading-main-idea',
  'reading-word-maze',
  'reading-grid-mask',
  'reading-snake',
  'reading-line-pace',
};

bool usesReadingContentBank(String trainerKey) =>
    readingContentBankTrainerKeys.contains(trainerKey);

/// Assignment validation never resolves content on the device. Historical full
/// snapshots remain valid even after their source material has been removed.
String? validateReadingContentSelection(Map<String, dynamic> raw) {
  if (raw['__runtimeSnapshot'] is Map) return null;
  final selection = raw['contentBank'];
  if (selection is! Map ||
      selection['libraryId'] != readingContentBankLibraryId ||
      selection['materialIds'] is! List ||
      (selection['materialIds'] as List).isEmpty) {
    return 'Выберите материалы из банка.';
  }
  return null;
}

/// A seed is insufficient to reproduce retired content. Only prepared payloads
/// may start reading scenes; their existing field names are kept for history.
bool hasPreparedReadingContent(String trainerKey, Map<String, dynamic> params) {
  if (!usesReadingContentBank(trainerKey)) return true;
  final payload = readTrainerRuntimeSnapshot(trainerKey, params);
  if (payload == null) return false;
  switch (trainerKey) {
    case 'letter-first-by-sound':
    case 'word-cubes':
      return payload['rounds'] is List &&
          (payload['rounds'] as List).isNotEmpty;
    case 'letter-word-link':
      return payload['round'] is Map;
    case 'letter-place-in-word':
      return payload['tasks'] is List &&
          (payload['tasks'] as List).isNotEmpty &&
          payload['pool'] is List;
    case 'reading-anagram':
      return payload['letters'] is List && payload['order'] is List;
    case 'reading-phrases':
      return payload['phrases'] is List &&
          (payload['phrases'] as List).isNotEmpty;
    case 'reading-cloze':
      return payload['choices'] is List && payload['prompt'] is String;
    case 'reading-story-order':
      return payload['sentences'] is List && payload['order'] is List;
    case 'reading-find-span':
      return payload['words'] is List && payload['targetIndexes'] is List;
    case 'reading-word-sprint':
      return payload['words'] is List && payload['sentences'] is List;
    case 'reading-word-maze':
      return payload['words'] is List && payload['path'] is List;
    default:
      return payload['text'] is String &&
          (payload['text'] as String).isNotEmpty;
  }
}
