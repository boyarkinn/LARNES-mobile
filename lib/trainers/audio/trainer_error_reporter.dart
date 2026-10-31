import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:package_info_plus/package_info_plus.dart';

final _reporters = Expando<_NativeTrainerErrorReporter>();
Map<String, Object?>? _version;

Future<Map<String, Object?>> nativeTrainerVersionMetadata() async {
  if (_version != null) return _version!;
  try {
    final info = await PackageInfo.fromPlatform().timeout(const Duration(seconds: 1));
    return _version = <String, Object?>{
      if (RegExp(r'^[a-zA-Z0-9.+_-]{1,40}$').hasMatch(info.version))
        'appVersion': info.version,
      if (int.tryParse(info.buildNumber) case final int code
          when code >= 0 && code <= 2147483647)
        'buildCode': code,
    };
  } catch (_) {
    return <String, Object?>{};
  }
}

/// Non-blocking and content-free. The API proves the child/assignment again.
void reportNativeTrainerAudioIssue({
  required ParentApi api,
  required Map<String, Object?> issue,
  required String trainerKey,
  String? childId,
  String? assignmentId,
  int? stepIndex,
}) {
  final reporter = _reporters[api] ??= _NativeTrainerErrorReporter(
    api.reportTrainerRuntimeError,
  );
  reporter.report(
    issue,
    trainerKey: trainerKey,
    childId: childId,
    assignmentId: assignmentId,
    stepIndex: stepIndex,
  );
}

class _NativeTrainerErrorReporter {
  _NativeTrainerErrorReporter(this.send);
  final Future<int> Function(Map<String, Object?>) send;
  final _queue = <Map<String, Object?>>[];
  bool _flushing = false;
  Timer? _retry;

  String _id() {
    final random = Random.secure(),
        bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  void report(
    Map<String, Object?> issue, {
    required String trainerKey,
    String? childId,
    String? assignmentId,
    int? stepIndex,
  }) {
    final code = issue['code'];
    if (code is! String ||
        !RegExp(
          r'^(AUDIO-(MISSING|INTEGRITY|TIMEOUT|NETWORK|URL|MEMORY|STORAGE|UNKNOWN|MIXED|PLAYBACK|BLOCKED|STALLED|DECODE|INSTRUCTION|HTTP-[1-5][0-9]{2})|CATALOG-(TIMEOUT|NETWORK|UNKNOWN))$',
        ).hasMatch(code)) {
      return;
    }
    final playback =
        issue['stage'] == 'audio-playback' || issue['stage'] == 'play';
    final hashes =
        (issue['failedSha256'] is List
                ? issue['failedSha256'] as List
                : const [])
            .whereType<String>()
            .where((hash) => RegExp(r'^[a-f0-9]{64}$').hasMatch(hash))
            .take(5)
            .toList();
    final elapsed = issue['elapsedMs'] ?? issue['durationMs'];
    final now = DateTime.now().toUtc();
    _queue.add({
      'eventId': _id(),
      'occurredAt': now.toIso8601String(),
      'source': childId != null && assignmentId != null && stepIndex != null
          ? 'homework'
          : 'direct',
      if (childId != null && assignmentId != null && stepIndex != null) ...{
        'childId': childId,
        'assignmentId': assignmentId,
        'stepIndex': stepIndex,
      },
      'phase': code.startsWith('CATALOG-')
          ? 'manifest'
          : playback
          ? 'audio_play'
          : 'audio_prepare',
      'code': code,
      'trainerKey': trainerKey,
      'durationMs': elapsed is num ? elapsed.round().clamp(0, 120000) : 0,
      'runtime': 'native',
      'os': Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : 'other',
      'stage': playback
          ? 'play'
          : issue['stage'] == 'instruction'
          ? 'instruction'
          : issue['stage'] == 'decode'
          ? 'decode'
          : 'download',
      if (hashes.isNotEmpty) 'failedSha256': hashes,
    });
    _prune();
    unawaited(_flush());
  }

  void _prune() {
    final cutoff = DateTime.now().toUtc().subtract(const Duration(minutes: 30));
    _queue.removeWhere(
      (item) =>
          DateTime.tryParse(item['occurredAt'] as String)?.isBefore(cutoff) !=
          false,
    );
    if (_queue.length > 8) _queue.removeRange(0, _queue.length - 8);
  }

  Future<void> _flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      _prune();
      final version = await nativeTrainerVersionMetadata();
      while (_queue.isNotEmpty) {
        final item = _queue.first;
        int status;
        try {
          status = await send({
            ...item,
            ...version,
          }).timeout(const Duration(seconds: 5));
        } catch (_) {
          status = 0;
        }
        if (status == 0 || status == 429 || status >= 500) break;
        if (_queue.contains(item)) _queue.remove(item);
      }
    } finally {
      _flushing = false;
      if (_queue.isEmpty) {
        _retry?.cancel();
        _retry = null;
      }
      if (_queue.isNotEmpty && _retry == null) {
        _retry = Timer(const Duration(seconds: 15), () {
          _retry = null;
          unawaited(_flush());
        });
      }
    }
  }
}
