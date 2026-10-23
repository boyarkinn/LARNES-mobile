import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:larnes_mobile/features/messenger/messenger_api.dart';
import 'package:larnes_mobile/features/messenger/messenger_files.dart';
import 'package:larnes_mobile/features/messenger/messenger_scope.dart';
import 'package:larnes_mobile/features/messenger/messenger_wire.dart';

const messengerFileLimit = 4;
const messengerFileBytes = 20 * 1024 * 1024;

class MessengerUpload {
  MessengerUpload({
    required this.id,
    required this.name,
    this.status = 'uploading',
  });

  final String id;
  final String name;
  String status;
  int sent = 0;
  int total = 0;
  final DateTime startedAt = DateTime.now();
  CancelToken? cancel;
}

class MessengerPending {
  MessengerPending({
    required this.clientKey,
    required this.body,
    required this.fileIds,
    this.replyToMessageId,
  });

  final String body;
  final String clientKey;
  final List<String> fileIds;
  final String? replyToMessageId;
}

/// One conversation in this process. Closing the panel does not drop an in-flight send.
class MessengerRoom extends ChangeNotifier {
  MessengerRoom({required this.scope, required this.gateway});

  final MessengerGateway gateway;
  final MessengerScope scope;

  MessengerCapabilities? capabilities;
  String draft = '';
  String? earlier;
  String? errorCode;
  final List<MessengerEntry> entries = [];
  bool paused = false;
  MessengerPending? pending;
  String? replyTo;
  bool sending = false;
  bool stuck = true;
  int unread = 0;
  final List<MessengerUpload> uploads = [];
  bool visible = false;

  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;
  bool _pulling = false;
  final Set<String> _redacted = {};
  final Map<String, String> _reportKeys = {};
  String? commandNotice;

  void setDraft(String value) {
    draft = value;
    notifyListeners();
  }

  void setReply(String? messageId) {
    replyTo = messageId;
    notifyListeners();
  }

  void setStuck(bool value) {
    if (stuck == value) return;
    stuck = value;
    if (stuck) unawaited(_markVisible());
  }

  void setVisible(bool open) {
    if (_disposed) return;
    paused = false;
    visible = open;
    unawaited(MessengerFileCache.prune().catchError((_) {}));
    if (open) unread = 0;
    _schedule(immediate: true);
    notifyListeners();
  }

  void pause() {
    paused = true;
    _generation++;
    if (gateway is MessengerApi) (gateway as MessengerApi).cancelScope(scope);
    _timer?.cancel();
    _timer = null;
  }

  void resume() {
    if (_disposed) return;
    paused = false;
    unawaited(MessengerFileCache.prune().catchError((_) {}));
    _schedule(immediate: true);
  }

  /// One authorization and history step. Used by the poll and by the narrow test.
  Future<String?> pull() async {
    if (_disposed || paused || _pulling) return null;
    _pulling = true;
    final generation = _generation;
    try {
      if (!scope.canOpen) {
        _revoke('forbidden');
        return 'forbidden';
      }
      if (visible) return await _pullOpen(generation);
      final summary = await _safe(() => gateway.summary(scope));
      if (!_current(generation)) return null;
      await _pollUploads(generation);
      final summaryCode = _code(summary);
      if (summaryCode != null) {
        if (summaryCode == 'forbidden') {
          _revoke('forbidden');
        } else {
          _fail(summaryCode);
        }
        return summaryCode;
      }
      if (summary is MessengerOk<({int unread, int waitMs})>) {
        unread = summary.value.unread;
        errorCode = null;
        notifyListeners();
        return null;
      }
      return null;
    } finally {
      _pulling = false;
    }
  }

  Future<void> send() async {
    if (_disposed || sending || capabilities?.send != true) return;
    if (uploads.any((file) => file.status != 'ready')) return;
    final body = draft;
    final files = uploads.map((file) => file.id).toList();
    if (body.trim().isEmpty && files.isEmpty) return;
    final previous = pending;
    final same =
        previous != null &&
        previous.body == body &&
        previous.replyToMessageId == replyTo &&
        previous.fileIds.join() == files.join();
    final item = same
        ? previous
        : MessengerPending(
            clientKey: messengerClientKey(),
            body: body,
            fileIds: files,
            replyToMessageId: replyTo,
          );
    pending = item;
    sending = true;
    errorCode = null;
    notifyListeners();
    final result = await _safe(
      () => gateway.send(
        scope,
        body: item.body,
        clientKey: item.clientKey,
        fileIds: item.fileIds,
        replyToMessageId: item.replyToMessageId,
      ),
    );
    if (_disposed || pending?.clientKey != item.clientKey) return;
    final sendCode = _code(result);
    if (sendCode != null) {
      sending = false;
      if (sendCode == 'forbidden') {
        _revoke('forbidden');
        return;
      }
      errorCode = sendCode;
      if (sendCode == 'closed') {
        capabilities = const MessengerCapabilities(read: true, send: false);
      }
      notifyListeners();
      return;
    }
    if (result is MessengerOk<MessengerSent>) {
      pending = null;
      sending = false;
      draft = '';
      replyTo = null;
      final sentFiles = uploads.map((file) => file.id).toList();
      uploads.clear();
      for (final id in sentFiles) {
        unawaited(_safe(() => gateway.cancelFile(scope, id)));
      }
      errorCode = null;
      _merge([
        MessengerEntry(
          author: result.value.author,
          authorParticipantId: capabilities?.authorParticipantId,
          redacted: result.value.redacted,
          body: result.value.body,
          fileIds: result.value.fileIds,
          messageId: result.value.id,
          seq: result.value.seq,
        ),
      ]);
      notifyListeners();
    }
  }

  Future<void> pickAndUpload() async {
    final generation = _generation;
    if (!_current(generation) || capabilities?.send != true) return;
    try {
      final picked = await pickMessengerFiles();
      if (!_current(generation)) return;
      await addFiles(
        picked.map((file) => (name: file.name, bytes: file.bytes)).toList(),
      );
    } catch (_) {
      if (_current(generation)) _fail('file');
    }
  }

  Future<void> addFiles(List<({String name, Uint8List bytes})> files) async {
    if (capabilities?.send != true) return;
    for (final file in files) {
      if (uploads.length >= messengerFileLimit) {
        errorCode = 'file';
        notifyListeners();
        return;
      }
      if (file.bytes.isEmpty || file.bytes.length > messengerFileBytes) {
        errorCode = 'file';
        notifyListeners();
        continue;
      }
      final upload = MessengerUpload(
        id: messengerClientKey(),
        name: _fileName(file.name),
      );
      upload.total = file.bytes.length;
      upload.cancel = CancelToken();
      uploads.add(upload);
      notifyListeners();
      final mime = messengerMime(upload.name);
      final result = await _safe(
        () => gateway.upload(
          scope,
          id: upload.id,
          name: upload.name,
          mime: mime,
          bytes: file.bytes,
          cancel: upload.cancel,
          onProgress: (sent, total) {
            upload.sent = sent;
            upload.total = total;
            if (!_disposed) notifyListeners();
          },
        ),
      );
      if (_disposed || !uploads.contains(upload)) return;
      final uploadCode = _code(result);
      if (uploadCode != null) {
        upload.status = 'error';
        if (uploadCode == 'forbidden') {
          _revoke('forbidden');
          return;
        }
        errorCode = uploadCode == 'unavailable' ? 'file' : uploadCode;
      } else if (result is MessengerOk<MessengerFileCard>) {
        upload.status = result.value.status;
      }
      notifyListeners();
    }
  }

  Future<void> cancelUpload(String id) async {
    final upload = uploads.cast<MessengerUpload?>().firstWhere(
      (file) => file?.id == id,
      orElse: () => null,
    );
    if (upload == null) return;
    upload.cancel?.cancel();
    uploads.remove(upload);
    notifyListeners();
    await _safe(() => gateway.cancelFile(scope, id));
  }

  Future<void> loadEarlier() async {
    final cursor = earlier;
    if (cursor == null) return;
    final page = await _safe(() => gateway.history(scope, before: cursor));
    if (_disposed || paused) return;
    final earlierCode = _code(page);
    if (earlierCode != null) {
      if (earlierCode == 'forbidden') _revoke('forbidden');
      return;
    }
    if (page is MessengerOk<MessengerPage>) {
      earlier = page.value.nextCursor;
      _merge(page.value.entries);
      notifyListeners();
    }
  }

  Future<String?> openFile(String id) => _materialize(id, share: false);

  Future<String?> shareFile(String id) => _materialize(id, share: true);

  @override
  void dispose() {
    pause();
    _disposed = true;
    _generation += 1;
    _timer?.cancel();
    for (final upload in uploads) {
      upload.cancel?.cancel();
    }
    super.dispose();
  }

  Future<String?> _pullOpen(int generation) async {
    final opened = await _safe(() => gateway.open(scope));
    if (!_current(generation)) return null;
    final openedCode = _code(opened);
    if (openedCode != null) {
      if (openedCode == 'forbidden') {
        _revoke('forbidden');
      } else {
        _fail(openedCode);
      }
      return openedCode;
    }
    if (opened is! MessengerOk<MessengerCapabilities>) return 'unavailable';
    capabilities = opened.value;
    if (!opened.value.read) {
      _revoke('forbidden');
      return 'forbidden';
    }
    if (!opened.value.send) {
      for (final upload in uploads) {
        upload.cancel?.cancel();
      }
      uploads.clear();
      if (pending != null) errorCode = 'closed';
      sending = false;
    }
    final cursor = entries.isEmpty ? null : entries.last.seq;
    final page = cursor == null
        ? await _safe(() => gateway.history(scope, before: messengerTailCursor))
        : await _safe(() => gateway.history(scope, after: cursor));
    if (!_current(generation)) return null;
    final pageCode = _code(page);
    if (pageCode != null) {
      if (pageCode == 'forbidden') {
        _revoke('forbidden');
      } else {
        _fail(pageCode);
      }
      return pageCode;
    }
    if (page is MessengerOk<MessengerPage>) {
      if (cursor == null) earlier = page.value.nextCursor;
      _merge(page.value.entries);
      errorCode = capabilities?.send == false && pending != null
          ? 'closed'
          : null;
      notifyListeners();
      if (stuck) await _markVisible();
    }
    await _pollUploads(generation);
    return null;
  }

  Future<void> _markVisible() async {
    if (_disposed || paused || !visible || entries.isEmpty) return;
    final generation = _generation;
    final cursor = entries.last.seq;
    final marked = await _safe(() => gateway.markRead(scope, cursor));
    if (_current(generation) && _code(marked) == 'forbidden') {
      _revoke('forbidden');
    }
  }

  Future<void> _pollUploads(int generation) async {
    for (final upload in uploads.toList()) {
      if (!_current(generation)) return;
      if (upload.status != 'quarantine' && upload.status != 'uploading') {
        continue;
      }
      if (upload.status == 'uploading') continue;
      if (DateTime.now().difference(upload.startedAt) >
          const Duration(minutes: 3)) {
        upload.status = 'error';
        errorCode = 'file';
        notifyListeners();
        continue;
      }
      final result = await _safe(() => gateway.fileStatus(scope, upload.id));
      if (!_current(generation) || !uploads.contains(upload)) return;
      if (result is MessengerOk<MessengerFileCard>) {
        upload.status = result.value.status;
        notifyListeners();
      } else if (_code(result) == 'forbidden') {
        _revoke('forbidden');
        return;
      }
    }
  }

  Future<String?> _materialize(String id, {required bool share}) async {
    final generation = _generation;
    if (!_current(generation)) return null;
    final bytes = await _safe(() => gateway.download(scope, id));
    if (!_current(generation)) return null;
    if (bytes is! MessengerOk<Uint8List>) {
      if (_code(bytes) == 'forbidden') {
        _revoke('forbidden');
      } else {
        _fail('file');
      }
      return null;
    }
    final card = await _safe(() => gateway.fileMeta(scope, id));
    if (!_current(generation)) return null;
    if (card is! MessengerOk<MessengerFileCard> ||
        card.value.status != 'ready') {
      if (_code(card) == 'forbidden') {
        _revoke('forbidden');
      } else {
        _fail('file');
      }
      return null;
    }
    if (bytes.value.length > messengerFileBytes ||
        card.value.bytes != null && card.value.bytes != bytes.value.length) {
      _fail('file');
      return null;
    }
    try {
      final path = await MessengerFileCache.write(
        card.value.name ?? id,
        bytes.value,
        ownerKey: scope.sessionKey,
        valid: () => _current(generation),
      );
      if (!_current(generation)) {
        await MessengerFileCache.remove(path);
        return null;
      }
      if (share) {
        await MessengerFileCache.share(path);
      } else {
        await MessengerFileCache.open(path);
      }
      return _current(generation) ? path : null;
    } catch (_) {
      if (_current(generation)) _fail('file');
      return null;
    }
  }

  void _merge(List<MessengerEntry> incoming) {
    for (final entry in [...entries, ...incoming]) {
      if ((entry.access && entry.action == 'redacted' || entry.redacted) &&
          entry.messageId != null) {
        _redacted.add(entry.messageId!);
      }
    }
    final bySeq = <String, MessengerEntry>{
      for (final entry in entries) entry.seq: entry,
      for (final entry in incoming) entry.seq: entry,
    };
    final sorted = bySeq.values.toList()
      ..sort((a, b) => BigInt.parse(a.seq).compareTo(BigInt.parse(b.seq)));
    entries
      ..clear()
      ..addAll(
        sorted.map(
          (entry) => !entry.access && _redacted.contains(entry.messageId)
              ? MessengerEntry(
                  seq: entry.seq,
                  author: entry.author,
                  authorParticipantId: entry.authorParticipantId,
                  messageId: entry.messageId,
                  replyToMessageId: entry.replyToMessageId,
                  redacted: true,
                )
              : entry,
        ),
      );
  }

  void _revoke(String code) {
    if (_disposed) return;
    pause();
    for (final upload in uploads) {
      upload.cancel?.cancel();
    }
    sending = false;
    _redacted.clear();
    entries.clear();
    draft = '';
    pending = null;
    uploads.clear();
    capabilities = const MessengerCapabilities(read: false, send: false);
    errorCode = code;
    unread = 0;
    notifyListeners();
  }

  void _fail(String code) {
    if (_disposed) return;
    errorCode = code;
    notifyListeners();
  }

  bool _current(int generation) =>
      !_disposed && !paused && generation == _generation;
  Future<MessengerValue<T>> _safe<T>(
    Future<MessengerValue<T>> Function() work,
  ) async {
    try {
      return await work().timeout(const Duration(minutes: 2));
    } catch (_) {
      return const MessengerDenied('unavailable');
    }
  }

  Future<void> command(String action, MessengerEntry entry) async {
    if (_disposed ||
        paused ||
        gateway is! MessengerApi ||
        entry.messageId == null) {
      return;
    }
    final generation = _generation;
    final result = await _safe(
      () => (gateway as MessengerApi).command(scope, {
        'action': action,
        'messageId': entry.messageId,
        if (action == 'report') 'category': 'violation',
        if (action == 'report')
          'clientKey': _reportKeys.putIfAbsent(
            entry.messageId!,
            messengerClientKey,
          ),
      }),
    );
    if (!_current(generation)) return;
    if (result is MessengerDenied<void>) {
      if (result.code == 'forbidden') {
        _revoke('forbidden');
      } else {
        _fail(result.code);
      }
      return;
    }
    commandNotice = action == 'report' ? 'reported' : 'removed';
    if (action == 'redact') {
      _redacted.add(entry.messageId!);
      _merge([]);
    }
    errorCode = null;
    notifyListeners();
  }

  void _schedule({required bool immediate}) {
    _timer?.cancel();
    if (paused || _disposed) return;
    final delay = immediate ? Duration.zero : const Duration(seconds: 2);
    _timer = Timer(delay, () async {
      await pull();
      if (!_disposed && !paused) _schedule(immediate: false);
    });
  }
}

class MessengerRooms {
  static const _max = 8;
  static final Map<String, MessengerRoom> _rooms = {};

  static MessengerRoom retain(
    MessengerScope scope, {
    MessengerGateway? gateway,
  }) {
    final stale = _rooms.entries.where((entry) {
      final room = entry.value;
      return room.scope.ownerKey == scope.ownerKey &&
          room.scope.childId != scope.childId;
    }).toList();
    for (final entry in stale) {
      entry.value.dispose();
      _rooms.remove(entry.key);
    }
    final existing = _rooms[scope.sessionKey];
    if (existing != null) return existing;
    while (_rooms.length >= _max) {
      final victim = _rooms.entries.firstWhere(
        (entry) => !entry.value.visible,
        orElse: () => _rooms.entries.first,
      );
      victim.value.dispose();
      _rooms.remove(victim.key);
    }
    final room = MessengerRoom(
      scope: scope,
      gateway: gateway ?? MessengerApi(),
    );
    _rooms[scope.sessionKey] = room;
    return room;
  }

  static Future<void> clear() async {
    for (final room in _rooms.values) {
      room.dispose();
    }
    _rooms.clear();
    await MessengerFileCache.clear();
  }

  static Future<void> clearGuest() async {
    final guests = _rooms.entries
        .where(
          (entry) => entry.value.scope.credential == MessengerCredential.guest,
        )
        .toList();
    for (final entry in guests) {
      entry.value.dispose();
      _rooms.remove(entry.key);
    }
    await MessengerFileCache.clear();
  }

  static int get length => _rooms.length;
}

String? _code<T>(MessengerValue<T> value) {
  if (value is MessengerDenied<T>) return value.code;
  return null;
}

String _fileName(String name) {
  final slash = name.replaceAll('\\', '/');
  final base = slash.split('/').last.trim();
  return base.isEmpty ? 'file' : base;
}
