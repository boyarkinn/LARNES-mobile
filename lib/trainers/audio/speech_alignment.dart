/// Timing follows the original audio clock; text offsets use UTF-16 on both platforms.
class SpeechWordTiming {
  const SpeechWordTiming({
    required this.startOffset,
    required this.endOffset,
    required this.startMs,
    required this.endMs,
  });
  final int startOffset;
  final int endOffset;
  final int startMs;
  final int endMs;
}

class SpeechAlignment {
  const SpeechAlignment({required this.words});
  final List<SpeechWordTiming> words;
  int endOffsetAt(int positionMs) {
    var low = 0, high = words.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (words[middle].endMs <= positionMs) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low > 0 ? words[low - 1].endOffset : 0;
  }

  static SpeechAlignment? fromJson(Object? raw, String text, int durationMs) {
    if (raw is! Map ||
        raw['version'] != 1 ||
        raw['words'] is! List ||
        text.isEmpty)
      return null;
    final result = <SpeechWordTiming>[];
    var previousOffset = 0, previousEnd = 0;
    for (final item in raw['words'] as List) {
      if (item is! Map) return null;
      final start = item['startOffset'], end = item['endOffset'];
      final startMs = item['startMs'], endMs = item['endMs'];
      if (start is! int ||
          end is! int ||
          startMs is! int ||
          endMs is! int ||
          start < previousOffset ||
          end <= start ||
          end > text.length ||
          startMs < previousEnd ||
          endMs < startMs ||
          endMs > durationMs ||
          text.substring(start, end).trim().isEmpty)
        return null;
      result.add(
        SpeechWordTiming(
          startOffset: start,
          endOffset: end,
          startMs: startMs,
          endMs: endMs,
        ),
      );
      previousOffset = end;
      previousEnd = endMs;
    }
    return result.isEmpty
        ? null
        : SpeechAlignment(words: List.unmodifiable(result));
  }
}
