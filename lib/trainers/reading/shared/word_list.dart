import 'content_bank.dart';

bool isWordListTrainerKey(String key) =>
    const {'reading-word-columns', 'reading-marathon'}.contains(key);
List<String> readingWordListCategoryIds(Map selection) {
  final explicit = selection['categoryIds'];
  final values = explicit == null
      ? (selection['categoryId'] is String
            ? [selection['categoryId']]
            : const [])
      : explicit is List
      ? explicit
      : const [];
  return values.whereType<String>().toSet().toList();
}

String readingWordListCategorySummary(
  List<Map> categories,
  List<String> selected,
) => categories
    .where((topic) => topic['parentId'] == null)
    .expand((topic) {
      final children = categories
              .where((item) => item['parentId'] == topic['id'])
              .toList(),
          chosen = categories
              .where(
                (item) =>
                    item['parentId'] == topic['id'] &&
                    selected.contains(item['id']),
              )
              .toList();
      return chosen.isEmpty
          ? <String>[]
          : [
              chosen.length == children.length
                  ? topic['title'].toString()
                  : '${topic['title']}: ${chosen.map((item) => item['title']).join(', ')}',
            ];
    })
    .join(', ');
String? validateReadingWordListRaw(
  Map<String, dynamic> raw, {
  bool allowMultiple = false,
}) {
  if (raw['__runtimeSnapshot'] is Map) return null;
  final selection = raw['contentBank'];
  if (allowMultiple) {
    if (selection is! Map ||
        selection['libraryId'] != readingContentBankLibraryId) {
      return 'Выберите подтемы.';
    }
    final ids = selection['categoryIds'];
    if (ids != null &&
        (ids is! List ||
            ids.isEmpty ||
            ids.length > 500 ||
            ids.any((id) => id is! String || id.isEmpty))) {
      return 'Выберите подтемы.';
    }
    return readingWordListCategoryIds(selection).isNotEmpty
        ? null
        : 'Выберите подтемы.';
  }
  return selection is Map &&
          selection['libraryId'] == readingContentBankLibraryId &&
          selection['categoryId'] is String &&
          (selection['categoryId'] as String).isNotEmpty
      ? null
      : 'Выберите тему и подтему.';
}
