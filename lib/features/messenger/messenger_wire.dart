class MessengerCapabilities {
  const MessengerCapabilities({
    required this.read,
    required this.send,
    this.authorParticipantId,
    this.moderate = false,
  });

  final String? authorParticipantId;
  final bool moderate;
  final bool read;
  final bool send;
}

class MessengerEntry {
  const MessengerEntry({
    required this.seq,
    this.access = false,
    this.action,
    this.author = '',
    this.authorParticipantId,
    this.redacted = false,
    this.body = '',
    this.fileIds = const [],
    this.messageId,
    this.replyToMessageId,
  });

  final String? authorParticipantId;
  final bool redacted;
  final bool access;
  final String? action;
  final String author;
  final String body;
  final List<String> fileIds;
  final String? messageId;
  final String? replyToMessageId;
  final String seq;
}

class MessengerPage {
  const MessengerPage({required this.entries, this.nextCursor});

  final List<MessengerEntry> entries;
  final String? nextCursor;
}

class MessengerSent {
  const MessengerSent({
    required this.author,
    required this.body,
    required this.fileIds,
    required this.id,
    required this.seq,
    this.redacted = false,
  });

  final bool redacted;
  final String author;
  final String body;
  final List<String> fileIds;
  final String id;
  final String seq;
}

class MessengerFileCard {
  const MessengerFileCard({
    required this.id,
    required this.status,
    this.bytes,
    this.detail,
    this.name,
  });

  final int? bytes;
  final String? detail;
  final String id;
  final String? name;
  final String status;
}

class MessengerArchiveRow {
  const MessengerArchiveRow({
    required this.conversationId,
    required this.lessonSessionId,
    required this.occurredAt,
    required this.participants,
    required this.preview,
    required this.title,
    required this.unread,
  });

  final String conversationId;
  final String lessonSessionId;
  final String occurredAt;
  final List<String> participants;
  final String preview;
  final String title;
  final int unread;
}

class MessengerArchivePage {
  const MessengerArchivePage({required this.rows, this.nextCursor});

  final String? nextCursor;
  final List<MessengerArchiveRow> rows;
}

sealed class MessengerValue<T> {
  const MessengerValue();
}

class MessengerOk<T> extends MessengerValue<T> {
  const MessengerOk(this.value);

  final T value;
}

class MessengerDenied<T> extends MessengerValue<T> {
  const MessengerDenied(this.code);

  final String code;
}

const messengerCursorPattern = r'^[1-9]\d{0,14}$';

MessengerPage? messengerPageFromJson(Object? body) {
  if (body is! Map) return null;
  final raw = body['entries'];
  if (raw is! List) return null;
  final entries = <MessengerEntry>[];
  for (final item in raw) {
    final entry = messengerEntryFromJson(item);
    if (entry == null) return null;
    entries.add(entry);
  }
  final cursor = body['nextCursor'];
  return MessengerPage(
    entries: entries,
    nextCursor: cursor is String && cursor.isNotEmpty ? cursor : null,
  );
}

MessengerEntry? messengerEntryFromJson(Object? body) {
  if (body is! Map) return null;
  final kind = body['kind'];
  if (kind == 'access') {
    final seq = body['seq'];
    if (seq is! String || !RegExp(messengerCursorPattern).hasMatch(seq)) {
      return null;
    }
    return MessengerEntry(
      access: true,
      action: body['action'] as String? ?? '',
      messageId: body['messageId'] as String?,
      seq: seq,
    );
  }
  if (kind != 'message' || body['message'] is! Map) return null;
  final message = Map<String, dynamic>.from(body['message'] as Map);
  final seq = message['seq'];
  final id = message['id'];
  if (seq is! String ||
      id is! String ||
      !RegExp(messengerCursorPattern).hasMatch(seq)) {
    return null;
  }
  return MessengerEntry(
    authorParticipantId: message['authorParticipantId'] as String?,
    redacted: message['redacted'] == true,
    author: message['authorDisplayName'] as String? ?? '',
    body: message['body'] as String? ?? '',
    fileIds: _strings(message['fileIds']),
    messageId: id,
    replyToMessageId: message['replyToMessageId'] as String?,
    seq: seq,
  );
}

MessengerCapabilities? messengerCapabilitiesFromJson(Object? body) {
  if (body is! Map || body['capabilities'] is! Map) return null;
  final capabilities = body['capabilities'] as Map;
  if (capabilities['read'] is! bool || capabilities['send'] is! bool) {
    return null;
  }
  return MessengerCapabilities(
    authorParticipantId: capabilities['authorParticipantId'] as String?,
    moderate: capabilities['moderate'] == true,
    read: capabilities['read'] as bool,
    send: capabilities['send'] as bool,
  );
}

MessengerSent? messengerSentFromJson(Object? body) {
  if (body is! Map || body['message'] is! Map) return null;
  final message = body['message'] as Map;
  final seq = message['seq'];
  final id = message['id'];
  if (seq is! String || id is! String) return null;
  return MessengerSent(
    redacted: message['redacted'] == true,
    author: message['authorDisplayName'] as String? ?? '',
    body: message['body'] as String? ?? '',
    fileIds: _strings(message['fileIds']),
    id: id,
    seq: seq,
  );
}

MessengerFileCard? messengerFileCardFromJson(Object? body) {
  if (body is! Map) return null;
  final id = body['id'];
  final status = body['status'];
  if (id is! String || status is! String) return null;
  final bytes = body['bytes'];
  return MessengerFileCard(
    id: id,
    status: status,
    bytes: bytes is num ? bytes.toInt() : null,
    detail: body['detail'] as String?,
    name: body['name'] as String?,
  );
}

MessengerArchivePage? messengerArchiveFromJson(Object? body) {
  if (body is! Map || body['rows'] is! List) return null;
  final rows = <MessengerArchiveRow>[];
  for (final item in body['rows'] as List) {
    final row = messengerArchiveRowFromJson(item);
    if (row == null) return null;
    rows.add(row);
  }
  final cursor = body['nextCursor'];
  return MessengerArchivePage(
    rows: rows,
    nextCursor: cursor is String && cursor.isNotEmpty ? cursor : null,
  );
}

MessengerArchiveRow? messengerArchiveRowFromJson(Object? body) {
  if (body is! Map) return null;
  final conversationId = body['conversationId'];
  final lessonSessionId = body['lessonSessionId'];
  final title = body['title'];
  if (conversationId is! String ||
      lessonSessionId is! String ||
      title is! String) {
    return null;
  }
  final unread = body['unread'];
  return MessengerArchiveRow(
    conversationId: conversationId,
    lessonSessionId: lessonSessionId,
    occurredAt: body['occurredAt'] as String? ?? '',
    participants: _strings(body['participants']),
    preview: body['preview'] as String? ?? '',
    title: title,
    unread: unread is num ? unread.toInt().clamp(0, 1 << 30) : 0,
  );
}

({int unread, int waitMs})? messengerSummaryFromJson(Object? body) {
  if (body is! Map || body['unread'] is! num) return null;
  final pause = body['pollAfterMs'];
  final wait = pause is num && pause >= 2000 ? pause.toInt() : 2000;
  return (
    unread: (body['unread'] as num).toInt().clamp(0, 1 << 30),
    waitMs: wait.clamp(2000, 30000),
  );
}

String? messengerErrorCode(Object? body, int? status) {
  if (status == 401 || status == 403) return 'forbidden';
  if (body is Map && body['error'] is String) return body['error'] as String;
  if (status != null && status >= 400) return 'unavailable';
  return null;
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}

String messengerWhen(String iso) {
  final parsed = DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) return '';
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$day.$month.${parsed.year} $hour:$minute';
}
