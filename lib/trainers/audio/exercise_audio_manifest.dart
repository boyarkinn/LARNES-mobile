// Контракт опубликованного каталога. Совпадает с web `wire.ts` / `resolve.ts`.

import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_warmup_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'speech_alignment.dart';

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
    this.alignment,
  });

  final int bytes;
  final SpeechAlignment? alignment;
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
            alignment: SpeechAlignment.fromJson(
              item['alignment'],
              item['text'] as String? ?? '',
              durationMs,
            ),
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

/// Scope warmup audio to its selected topics and keep the standard instruction.
ExerciseAudioManifest? scopeTrainerAudioForParams(
  ExerciseAudioManifest? manifest,
  String trainerKey,
  Map<String, dynamic> params,
) {
  if (manifest == null || trainerKey != 'abacus-warmup') {
    return manifest;
  }
  final rawTopics = params['warmupTopics'];
  if ((params['warmupType'] != null && params['warmupType'] is! String) ||
      (rawTopics != null && rawTopics is! List) ||
      (params['warmupNarratedTopics'] != null &&
          (params['warmupNarratedTopics'] is! List ||
              (params['warmupNarratedTopics'] as List).any(
                (id) => id is! String,
              )))) {
    return manifest;
  }
  late PhysicalGesturePlan plan;
  try {
    plan = warmupPlanForParams(
      params['warmupType'] as String? ?? 'simple-9',
      rawTopics as List?,
      (params['warmupNarratedTopics'] as List?)?.cast<String>(),
    );
  } on ArgumentError {
    return manifest;
  }
  final introductionKey = physicalGestureIntroductionKey(plan);
  final needed =
      params['warmupNarratedTopics'] == null &&
          params['withExplanations'] == false
      ? {introductionKey}
      : physicalGestureAudioKeys(plan).toSet();
  bool keep(String key) =>
      key == 'instruction:abacus-warmup' ||
      needed.contains(key) ||
      key.startsWith('music:background:');
  final clips = manifest.clips.where((clip) => keep(clip.semanticKey)).map((
    clip,
  ) {
    if (clip.semanticKey.startsWith('music:background:')) return clip;
    return PublishedAudioClip(
      bytes: clip.bytes,
      durationMs: clip.durationMs,
      locale: clip.locale,
      semanticKey: clip.semanticKey,
      sha256: clip.sha256,
      url: clip.url,
      versionId: clip.versionId,
      contentLocale: clip.contentLocale,
      isRequired: true,
      text: clip.text,
    );
  }).toList();
  return ExerciseAudioManifest(
    catalogRevision: manifest.catalogRevision,
    trainerKey: manifest.trainerKey,
    contentLocale: manifest.contentLocale,
    instructionLocale: manifest.instructionLocale,
    clips: clips,
    missing: manifest.missing.where((item) => keep(item.semanticKey)).toList(),
  );
}
