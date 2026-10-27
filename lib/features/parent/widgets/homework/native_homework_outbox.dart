import 'dart:convert';
import 'dart:io';
import 'dart:async';

/// One durable operation file per command, scoped to account, child and homework.
/// A complete flushed temporary file also survives interruption before rename.
class NativeHomeworkOutbox {
  NativeHomeworkOutbox(Directory base, List<String> scope)
    : directory = Directory('${base.path}/homework-native/${_scopeKey(scope)}');
  static String _scopeKey(List<String> scope) {
    if (scope.length != 4 ||
        scope.any(
          (id) => !RegExp(
            r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',
          ).hasMatch(id),
        )) {
      throw ArgumentError('scope');
    }
    final hex = scope.join().replaceAll('-', '');
    // Lossless UUID encoding keeps Windows paths short without a new hash/package.
    return base64UrlEncode([
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ]).replaceAll('=', '');
  }

  static final Map<String, Future<void>> _locks = {};
  Future<T> _locked<T>(Future<T> Function() body) async {
    final key = directory.absolute.path,
        previous = _locks[key] ?? Future<void>.value(),
        release = Completer<void>();
    _locks[key] = release.future;
    await previous;
    try {
      return await body();
    } finally {
      release.complete();
      if (identical(_locks[key], release.future)) {
        _locks.remove(key);
      }
    }
  }

  final Directory directory;
  Future<void> put(Map<String, dynamic> command) =>
      _locked(() => _put(command));
  Future<void> _put(Map<String, dynamic> command) async {
    final id = command['operationId'];
    if (id is! String || !RegExp(r'^[a-f0-9-]{36}$').hasMatch(id)) {
      throw ArgumentError('operation');
    }
    final text = jsonEncode(command);
    if (utf8.encode(text).length > 4 * 1024 * 1024) throw StateError('size');
    await directory.create(recursive: true);
    final temp = File('${directory.path}/$id.tmp');
    await temp.writeAsString(text, flush: true);
    await temp.rename('${directory.path}/$id.json');
  }

  Future<List<Map<String, dynamic>>> pending() => _locked(_pending);
  Future<List<Map<String, dynamic>>> _pending() async {
    if (!await directory.exists()) return [];
    final files = await directory
        .list()
        .where(
          (file) =>
              file is File &&
              RegExp(
                r'/[a-f0-9-]{36}\.(json|tmp)$',
              ).hasMatch(file.path.replaceAll('\\', '/')),
        )
        .cast<File>()
        .toList();
    if (files.length > 64) throw StateError('outbox_size');
    files.sort((a, b) => a.path.compareTo(b.path));
    final rows = <String, Map<String, dynamic>>{};
    for (final file in files) {
      if (await file.length() > 4 * 1024 * 1024) throw StateError('size');
      Map<String, dynamic> command;
      try {
        command = Map<String, dynamic>.from(
          jsonDecode(await file.readAsString()) as Map,
        );
      } on FormatException {
        final id = file.path
            .replaceAll('\\', '/')
            .split('/')
            .last
            .split('.')
            .first;
        if (file.path.endsWith('.tmp') && rows.containsKey(id)) {
          continue;
        }
        rethrow;
      }
      final id = command['operationId'] as String;
      if (!file.path.endsWith('/$id.json') &&
          !file.path.endsWith('\\$id.json') &&
          !file.path.endsWith('/$id.tmp') &&
          !file.path.endsWith('\\$id.tmp')) {
        throw StateError('identity');
      }
      rows[id] = command;
    }
    return rows.values.toList();
  }

  Future<void> acknowledge(String id) => _locked(() => _acknowledge(id));
  Future<void> _acknowledge(String id) async {
    if (!RegExp(r'^[a-f0-9-]{36}$').hasMatch(id)) {
      throw ArgumentError('operation');
    }
    for (final extension in ['json', 'tmp']) {
      final file = File('${directory.path}/$id.$extension');
      if (await file.exists()) await file.delete();
    }
  }
}
