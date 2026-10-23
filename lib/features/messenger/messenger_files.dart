import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const messengerExtensions = [
  'jpg',
  'jpeg',
  'png',
  'webp',
  'pdf',
  'txt',
  'docx',
  'xlsx',
  'pptx',
];

String messengerMime(String name) {
  final extension = _extension(name);
  return switch (extension) {
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.pdf' => 'application/pdf',
    '.txt' => 'text/plain',
    '.docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    '.pptx' =>
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    _ => 'application/octet-stream',
  };
}

class MessengerPickedFile {
  const MessengerPickedFile({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

/// Private temporary copies. This is not the public exercise-audio cache.
class MessengerFileCache {
  static Future<void> _queue = Future.value();
  static int _epoch = 0;
  static Future<T> _locked<T>(Future<T> Function() work) {
    final result = _queue.then((_) => work());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static Future<Directory> _root() async => Directory(
    _join((await getTemporaryDirectory()).path, 'larnes-messenger'),
  );
  static Future<void> _prune(Directory directory) async {
    if (!directory.existsSync()) return;
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && (await entity.lastModified()).isBefore(cutoff)) {
        await entity.delete();
      }
    }
  }

  static Future<void> prune() => _locked(() async {
    await _prune(await _root());
  });
  static Future<String> write(
    String name,
    Uint8List bytes, {
    required String ownerKey,
    required bool Function() valid,
  }) {
    final epoch = _epoch;
    return _locked(() async {
      if (epoch != _epoch || !valid()) throw StateError('stale_download');
      final root = await _root();
      await root.create(recursive: true);
      await _prune(root);
      final owner = base64Url.encode(utf8.encode(ownerKey)).replaceAll('=', '');
      final directory = Directory(_join(root.path, owner));
      await directory.create(recursive: true);
      if (epoch != _epoch || !valid()) throw StateError('stale_download');
      final safe = _baseName(name).replaceAll(RegExp(r'[^\w.\- ]'), '_');
      final file = File(
        _join(directory.path, '${DateTime.now().microsecondsSinceEpoch}-$safe'),
      );
      await file.writeAsBytes(bytes, flush: true);
      if (epoch != _epoch || !valid()) {
        await file.delete();
        throw StateError('stale_download');
      }
      return file.path;
    });
  }

  static Future<void> remove(String path) => _locked(() async {
    final file = File(path), root = await _root();
    if (file.parent.parent.absolute.path != root.absolute.path) {
      throw StateError('invalid_cache_path');
    }
    if (file.existsSync()) await file.delete();
  });
  static Future<void> open(String path) async {
    await OpenFilex.open(path);
  }

  static Future<void> share(String path) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }

  static Future<void> clear() {
    _epoch++; // Invalidate current writes before waiting for the filesystem queue.
    return _locked(() async {
      final root = await _root();
      if (root.existsSync()) await root.delete(recursive: true);
    });
  }
}

Future<List<MessengerPickedFile>> pickMessengerFiles() async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: messengerExtensions,
    withData: false,
  );
  if (result == null) return const [];
  final files = <MessengerPickedFile>[];
  if (result.files.length > 4 ||
      result.files.any(
        (file) => file.size > 20 * 1024 * 1024 || file.size < 1,
      )) {
    throw StateError('file_limit');
  }
  for (final file in result.files) {
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in File(
        file.path!,
      ).openRead(0, 20 * 1024 * 1024 + 1)) {
        builder.add(chunk);
      }
      bytes = builder.takeBytes();
    }
    if (bytes != null && bytes.length > 20 * 1024 * 1024) {
      throw StateError('file_limit');
    }
    if (bytes == null) continue;
    files.add(MessengerPickedFile(bytes: bytes, name: file.name));
  }
  return files;
}

String _join(String directory, String name) {
  final separator = Platform.pathSeparator;
  return directory.endsWith(separator)
      ? '$directory$name'
      : '$directory$separator$name';
}

String _baseName(String name) {
  final normalized = name.replaceAll('\\', '/');
  final parts = normalized.split('/');
  return parts.isEmpty ? 'file' : parts.last;
}

String _extension(String name) {
  final base = _baseName(name);
  final dot = base.lastIndexOf('.');
  if (dot < 0) return '';
  return base.substring(dot).toLowerCase();
}
