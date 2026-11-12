import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:larnes_mobile/features/parent/trainers/parent_trainer_play_session.dart';

/// One optional parent-chain destination, not general navigation restoration.
class TopicChainResumeStore {
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static String key(String ownerId) => 'topic-chain-resume:$ownerId';
  static String? pathFor(Map<String, dynamic> context) {
    final child = context['childId'];
    if (child is! String || !_uuid.hasMatch(child)) return null;
    if (context['source'] == 'direct' &&
        context['launchId'] is String &&
        _uuid.hasMatch(context['launchId'] as String)) {
      return '/parent/$child/trainers/play/topic-chain-flash';
    }
    final assignment = context['assignmentId'];
    if (context['source'] == 'homework' &&
        assignment is String &&
        _uuid.hasMatch(assignment) &&
        context['stepIndex'] is int &&
        (context['stepIndex'] as int) >= 0) {
      return '/parent/$child/homework/$assignment';
    }
    return null;
  }

  static Future<void> remember(
    String ownerId,
    Map<String, dynamic> context, {
    bool Function()? isCurrent,
  }) async {
    if (pathFor(context) == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (isCurrent?.call() == false) return;
    await prefs.setString(
      key(ownerId),
      jsonEncode({
        'at': DateTime.now().millisecondsSinceEpoch,
        'context': context,
      }),
    );
  }

  static Future<String?> read(String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key(ownerId));
    if (raw == null) return null;
    try {
      if (raw.length > 2048) throw const FormatException('size');
      final value = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final at = (value['at'] as num).toInt();
      final age = DateTime.now().millisecondsSinceEpoch - at;
      if (age < 0 || age > const Duration(days: 7).inMilliseconds) {
        throw const FormatException('expired');
      }
      final context = Map<String, dynamic>.from(value['context'] as Map);
      final path = pathFor(context);
      if (path == null) throw const FormatException('path');
      if (context['source'] == 'direct') {
        final session = await ParentTrainerPlaySessionStore.read(
          'topic-chain-flash',
        );
        if (session?.launchId != context['launchId']) {
          throw const FormatException('new-launch');
        }
      }
      return path;
    } catch (_) {
      await prefs.remove(key(ownerId));
      return null;
    }
  }

  static Future<void> clear(
    String ownerId, {
    Map<String, dynamic>? context,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (context != null) {
      try {
        final saved =
            jsonDecode(prefs.getString(key(ownerId)) ?? 'null') as Map;
        final actual = saved['context'] as Map;
        if (context.entries.any((entry) => actual[entry.key] != entry.value)) {
          return;
        }
      } catch (_) {
        return;
      }
    }
    await prefs.remove(key(ownerId));
  }
}
