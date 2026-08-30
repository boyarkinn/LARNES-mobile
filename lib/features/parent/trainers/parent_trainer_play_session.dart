import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ParentTrainerPlaySession {
  const ParentTrainerPlaySession({
    required this.params,
    this.returnPath,
    this.runtimeSnapshot,
  });

  final Map<String, dynamic> params;
  final String? returnPath;
  final Map<String, dynamic>? runtimeSnapshot;
}

class ParentTrainerPlaySessionStore {
  const ParentTrainerPlaySessionStore._();

  static String storageKey(String trainerKey) => 'parent-trainer-play:$trainerKey';

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
        return ParentTrainerPlaySession(
          params: Map<String, dynamic>.from(params),
          returnPath: isValidReturnPath(map['returnPath'] as String?)
              ? map['returnPath'] as String
              : null,
          runtimeSnapshot: runtimeSnapshot is Map
              ? Map<String, dynamic>.from(runtimeSnapshot)
              : null,
        );
      }

      return ParentTrainerPlaySession(
        params: Map<String, dynamic>.from(map),
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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey(trainerKey),
      jsonEncode({
        'version': 1,
        'params': params,
        'returnPath': isValidReturnPath(returnPath) ? returnPath : null,
        'runtimeSnapshot': runtimeSnapshot,
      }),
    );
  }
}
