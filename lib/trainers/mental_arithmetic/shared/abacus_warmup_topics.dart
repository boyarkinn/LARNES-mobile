const warmupTypes = [
  'simple-9',
  'simple-tens',
  'simple-2digit',
  'brothers',
  'friends',
];

List<int> warmupTopicNumbers(String type) {
  if (!warmupTypes.contains(type)) throw ArgumentError.value(type, 'type');
  return type == 'brothers'
      ? [4, 3, 2, 1]
      : type == 'friends'
      ? [9, 8, 7, 6, 5, 4, 3, 2, 1]
      : [1, 2, 3, 4, 5, 6, 7, 8, 9];
}

List<int> resolveWarmupTopics(String type, [List<int>? selected]) {
  final available = warmupTopicNumbers(type);
  if (selected == null) return available;
  if (selected.isEmpty ||
      selected.any((number) => !available.contains(number))) {
    throw ArgumentError('Выберите темы текущего вида разминки.');
  }
  return available.where(selected.contains).toList();
}

const warmupInstructionKey = 'instruction:abacus-warmup';

final warmupTopicIds = [
  for (final type in warmupTypes)
    for (final number in warmupTopicNumbers(type)) '$type:$number',
];

List<String> normalizeWarmupSelection(List<String> selected) {
  if (selected.isEmpty || selected.any((id) => !warmupTopicIds.contains(id))) {
    throw ArgumentError('Выберите хотя бы одну тему разминки.');
  }
  return warmupTopicIds.where(selected.contains).toList();
}

List<String> resolveWarmupSelection(String type, [List<dynamic>? selected]) {
  if (selected == null || selected.every((value) => value is int)) {
    return resolveWarmupTopics(
      type,
      selected?.cast<int>(),
    ).map((number) => '$type:$number').toList();
  }
  if (selected.any((value) => value is! String)) {
    throw ArgumentError('Неизвестная тема разминки.');
  }
  return normalizeWarmupSelection(selected.cast<String>());
}

String warmupOpeningKey(String type, [List<int>? selected]) {
  resolveWarmupTopics(type, selected);
  return warmupInstructionKey;
}

List<String> resolveWarmupNarratedTopics(
  List<String> selected,
  List<String>? narrated, {
  bool legacyEnabled = true,
}) {
  if (narrated == null) return legacyEnabled ? List.of(selected) : [];
  if (narrated.any((id) => !selected.contains(id)))
    throw ArgumentError('Озвучка доступна только для выбранных тем.');
  return selected.where(narrated.contains).toList();
}
