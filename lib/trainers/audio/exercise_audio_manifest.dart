// Контракт опубликованного каталога. Совпадает с web `wire.ts` / `resolve.ts`.

import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_gesture_cues.dart';

class PublishedAudioClip {
  const PublishedAudioClip({
    required this.bytes,
    required this.durationMs,
    required this.locale,
    required this.semanticKey,
    required this.sha256,
    required this.url,
    required this.versionId,
    this.contentLocale,
    this.isRequired,
    this.text = '',
  });

  final int bytes;
  final String? contentLocale;
  final bool? isRequired;
  final int durationMs;
  final String locale;
  final String semanticKey;
  final String sha256;
  final String text;
  final String url;
  final String versionId;
}

class MissingAudioBinding {
  const MissingAudioBinding({
    this.required,
    required this.locale,
    required this.reason,
    required this.semanticKey,
  });

  final String locale;
  final String reason;
  final bool? required;
  final String semanticKey;
}

class ExerciseAudioManifest {
  const ExerciseAudioManifest({
    required this.catalogRevision,
    required this.clips,
    required this.contentLocale,
    required this.instructionLocale,
    required this.missing,
    required this.trainerKey,
  });

  final int catalogRevision;
  final List<PublishedAudioClip> clips;
  final String contentLocale;
  final String instructionLocale;
  final List<MissingAudioBinding> missing;
  final String trainerKey;

  static ExerciseAudioManifest? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final clips = <PublishedAudioClip>[];
    final rawClips = raw['clips'];

    if (rawClips is List) {
      for (final item in rawClips) {
        if (item is! Map) {
          continue;
        }

        final url = item['url'];
        final bytes = item['bytes'];
        final durationMs = item['durationMs'];

        if (url is! String ||
            !url.startsWith('https://') ||
            bytes is! int ||
            durationMs is! int) {
          continue;
        }

        clips.add(
          PublishedAudioClip(
            bytes: bytes,
            contentLocale: item['contentLocale'] as String?,
            isRequired: item['required'] as bool?,
            durationMs: durationMs,
            locale: item['locale'] as String? ?? '',
            semanticKey: item['semanticKey'] as String? ?? '',
            sha256: item['sha256'] as String? ?? '',
            text: item['text'] as String? ?? '',
            url: url,
            versionId: item['versionId'] as String? ?? '',
          ),
        );
      }
    }

    final missing = <MissingAudioBinding>[];
    final rawMissing = raw['missing'];

    if (rawMissing is List) {
      for (final item in rawMissing) {
        if (item is! Map) {
          continue;
        }

        final reason = item['reason'];

        if (reason != 'unpublished' && reason != 'unknown_slot') {
          continue;
        }

        missing.add(
          MissingAudioBinding(
            locale: item['locale'] as String? ?? '',
            reason: reason as String,
            required: item['required'] as bool?,
            semanticKey: item['semanticKey'] as String? ?? '',
          ),
        );
      }
    }

    return ExerciseAudioManifest(
      catalogRevision: raw['catalogRevision'] as int? ?? 0,
      clips: clips,
      contentLocale: raw['contentLocale'] as String? ?? '',
      instructionLocale: raw['instructionLocale'] as String? ?? '',
      missing: missing,
      trainerKey: raw['trainerKey'] as String? ?? '',
    );
  }
}

ExerciseAudioManifest audioForLaunch({
  required ExerciseAudioManifest fresh,
  ExerciseAudioManifest? pinned,
}) {
  return pinned ?? fresh;
}

/// Practice-only warmups retain the standard instruction and omit action cues.
ExerciseAudioManifest? scopeTrainerAudioForParams(
  ExerciseAudioManifest? manifest,
  String trainerKey,
  Map<String, dynamic> params,
) {
  if (manifest == null ||
      trainerKey != 'abacus-warmup' ||
      params['withExplanations'] != false) {
    return manifest;
  }
  final introductionKey = warmupIntroCue(
    params['warmupType'] as String? ?? 'simple-9',
  );
  bool keep(String key) =>
      key == 'instruction:abacus-warmup' ||
      key == introductionKey ||
      key.startsWith('music:background:');
  return ExerciseAudioManifest(
    catalogRevision: manifest.catalogRevision,
    trainerKey: manifest.trainerKey,
    contentLocale: manifest.contentLocale,
    instructionLocale: manifest.instructionLocale,
    clips: manifest.clips.where((clip) => keep(clip.semanticKey)).toList(),
    missing: manifest.missing.where((item) => keep(item.semanticKey)).toList(),
  );
}
