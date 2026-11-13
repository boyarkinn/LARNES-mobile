import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:larnes_mobile/trainers/runtime/topic_chain_run_state.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';

class ParentTrainerPlaySession {
  const ParentTrainerPlaySession({
    required this.params,
    this.returnPath,
    this.runtimeSnapshot,
    this.launchId,
    this.audioManifest,
  });

  final Map<String, dynamic> params;
  final String? returnPath;
  final Map<String, dynamic>? runtimeSnapshot;
  final String? launchId;
  final ExerciseAudioManifest? audioManifest;
}

class ParentTrainerPlaySessionStore {
  const ParentTrainerPlaySessionStore._();

  static String storageKey(String trainerKey) =>
      'parent-trainer-play:$trainerKey';

  static bool isValidReturnPath(String? value) {
    return value != null &&
        value.startsWith('/parent/') &&
        !value.startsWith('//') &&
        !value.contains('\\');
  }

  static Future<ParentTrainerPlaySession?> read(String trainerKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey(trainerKey));

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map) {
        return null;
      }

      final map = Map<String, dynamic>.from(parsed);
      final version = map['version'];

      if (version == 1) {
        final params = map['params'];
        if (params is! Map) {
          return null;
        }

        final runtimeSnapshot = map['runtimeSnapshot'];
        final storedLaunchId = map['launchId'];
        final launchId =
            storedLaunchId is String &&
                RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(storedLaunchId)
            ? storedLaunchId
            : {
                'topic-chain-flash',
                'reading-word-columns',
                'reading-marathon',
              }.contains(trainerKey)
            ? topicChainUuid()
            : null;
        if (launchId != null && storedLaunchId != launchId) {
          await prefs.setString(
            storageKey(trainerKey),
            jsonEncode({...map, 'launchId': launchId}),
          );
        }
        return ParentTrainerPlaySession(
          params: Map<String, dynamic>.from(params),
          returnPath: isValidReturnPath(map['returnPath'] as String?)
              ? map['returnPath'] as String
              : null,
          runtimeSnapshot: runtimeSnapshot is Map
              ? Map<String, dynamic>.from(runtimeSnapshot)
              : null,
          launchId: launchId,
          audioManifest: ExerciseAudioManifest.fromJson(map['audioManifest']),
        );
      }

      final launchId =
          {
            'topic-chain-flash',
            'reading-word-columns',
            'reading-marathon',
          }.contains(trainerKey)
          ? topicChainUuid()
          : null;
      if (launchId != null) {
        await prefs.setString(
          storageKey(trainerKey),
          jsonEncode({'version': 1, 'params': map, 'launchId': launchId}),
        );
      }
      return ParentTrainerPlaySession(
        params: Map<String, dynamic>.from(map),
        launchId: launchId,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> write({
    required String trainerKey,
    required Map<String, dynamic> params,
    String? returnPath,
    Map<String, dynamic>? runtimeSnapshot,
    Map<String, dynamic>? audioManifest,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey(trainerKey),
      jsonEncode({
        'version': 1,
        'params': params,
        'returnPath': isValidReturnPath(returnPath) ? returnPath : null,
        'runtimeSnapshot': runtimeSnapshot,
        'audioManifest': audioManifest,
        if ({
          'topic-chain-flash',
          'reading-word-columns',
          'reading-marathon',
        }.contains(trainerKey))
          'launchId': topicChainUuid(),
      }),
    );
  }
}
