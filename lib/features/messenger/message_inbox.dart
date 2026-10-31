/// Volatile notification state. The server owns unread counts and read receipts.
class MessagePreview {
  const MessagePreview({
    required this.id,
    required this.lessonId,
    required this.childId,
    required this.author,
    required this.text,
    required this.at,
  });
  final String id, lessonId, childId, author, text;
  final int at;
  static MessagePreview? parse(Object? raw) {
    if (raw is! Map || raw['provider'] != 'larnes') return null;
    final id = raw['id'],
        lesson = raw['lessonSessionId'],
        child = raw['childId'],
        author = raw['author'],
        text = raw['text'],
        at = raw['at'];
    if (id is! String ||
        lesson is! String ||
        child is! String ||
        author is! String ||
        text is! String ||
        at is! num) {
      return null;
    }
    if (!RegExp(r'^[a-zA-Z0-9-]{8,80}$').hasMatch(id) ||
        !RegExp(r'^[a-zA-Z0-9-]{8,80}$').hasMatch(lesson) ||
        !RegExp(r'^[a-zA-Z0-9-]{8,80}$').hasMatch(child)) {
      return null;
    }
    return MessagePreview(
      id: id,
      lessonId: lesson,
      childId: child,
      author: author.substring(0, author.length.clamp(0, 80)),
      text: text.substring(0, text.length.clamp(0, 256)),
      at: at.toInt(),
    );
  }
}

class MessageInboxTracker {
  bool _initialized = false;
  final Set<String> _seen = {};
  int unread = 0;
  Map<String, int> children = {};
  Map<String, int> rooms = {};
  void clear() {
    _initialized = false;
    _seen.clear();
    unread = 0;
    children = {};
    rooms = {};
  }

  List<MessagePreview> update(
    Object? raw,
    int now, {
    bool Function(String)? reading,
  }) {
    if (raw is! Map || raw['unread'] is! num || raw['items'] is! List) {
      return [];
    }
    unread = (raw['unread'] as num).toInt().clamp(0, 1000000000);
    children = {
      if (raw['children'] is Map)
        for (final item in (raw['children'] as Map).entries)
          if (item.key is String && item.value is num)
            item.key as String: (item.value as num).toInt().clamp(
              0,
              1000000000,
            ),
    };
    rooms = {
      if (raw['rooms'] is Map)
        for (final item in (raw['rooms'] as Map).entries)
          if (item.key is String && item.value is num)
            item.key as String: (item.value as num).toInt().clamp(
              0,
              1000000000,
            ),
    };
    final baseline = !_initialized;
    _initialized = true;
    final incoming = <MessagePreview>[];
    for (final item in (raw['items'] as List).take(100)) {
      final notice = MessagePreview.parse(item);
      if (notice == null || !_seen.add(notice.id)) continue;
      if (!baseline &&
          now - notice.at < 30000 &&
          notice.at <= now + 5000 &&
          reading?.call(notice.lessonId) != true) {
        incoming.add(notice);
      }
    }
    while (_seen.length > 1024) {
      _seen.remove(_seen.first);
    }
    return incoming;
  }
}
