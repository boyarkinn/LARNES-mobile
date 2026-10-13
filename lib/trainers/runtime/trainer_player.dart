import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/trainers/audio/background_music.dart';
import 'package:larnes_mobile/trainers/audio/background_music_player.dart';
import 'package:larnes_mobile/trainers/audio/catalog_audio_cache.dart';
import 'package:larnes_mobile/trainers/audio/catalog_audio_store.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';
import 'package:larnes_mobile/trainers/audio/number_bank.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_key.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_step_chrome.dart';
import 'package:larnes_mobile/trainers/runtime/unimplemented_trainer.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';
import 'package:larnes_mobile/trainers/shared/theme/trainer_direction_theme.dart';

class TrainerPlayer extends StatefulWidget {
  const TrainerPlayer({
    super.key,
    required this.trainerKey,
    required this.params,
    required this.l10n,
    this.audioManifest,
    this.onComplete,
    this.runtimeSnapshot,
    this.stepChrome,
  });

  final String trainerKey;
  final Map<String, dynamic> params;
  final AppLocalizations l10n;
  final ExerciseAudioManifest? audioManifest;
  final VoidCallback? onComplete;
  final Map<String, dynamic>? runtimeSnapshot;
  final TrainerStepChrome? stepChrome;

  @override
  State<TrainerPlayer> createState() => _TrainerPlayerState();
}

class _TrainerPlayerState extends State<TrainerPlayer> {
  final TrainerBackgroundMusic _music = TrainerBackgroundMusic();
  ExerciseAudioManifest? _pinnedAudio;
  CatalogLaunch? _launch;
  CatalogSignal? _signal;
  var _pack = CatalogPack.missing;
  var _attempt = 0;
  var _alive = true;

  bool get _expectsStimuli => catalogExpectsStimuli(_pinnedAudio);

  TrainerDirection? get _direction {
    final key = TrainerKey.tryParse(widget.trainerKey);
    if (key == null) {
      return null;
    }
    return trainerDefinitions[key]?.direction;
  }

  @override
  void initState() {
    super.initState();
    // Первый кадр запуска фиксирует набор. Поздний ответ каталога его не меняет.
    _music.bind(_direction);
    _pinnedAudio = widget.audioManifest;
    final hasClips = widget.audioManifest?.clips.isNotEmpty ?? false;
    _pack = _expectsStimuli || hasClips ? CatalogPack.preparing : CatalogPack.missing;
    _prepare();
  }

  @override
  void dispose() {
    _alive = false;
    _signal?.cancel();
    _launch?.release();
    setNumberAudioFiles(const {});
    setSpeechAudioFiles(const {});
    setBackgroundMusicFiles(const {});
    unawaited(_music.dispose());
    super.dispose();
  }

  Future<void> _prepare() async {
    final manifest = _pinnedAudio;
    final expects = catalogExpectsStimuli(manifest);
    final hasClips = manifest?.clips.isNotEmpty ?? false;

    if (!expects && !hasClips) {
      return;
    }

    final signal = CatalogSignal();
    _signal = signal;

    try {
      final store = await sharedCatalogAudioStore();

      if (!_alive || !identical(_signal, signal)) {
        return;
      }

      final launch = await store.prepare(manifest, signal: signal);

      if (!_alive || !identical(_signal, signal)) {
        launch.release();
        return;
      }

      _launch?.release();
      _launch = launch;
      _bindNumberFiles(launch);

      if (!mounted) {
        return;
      }

      setState(() {
        _pack = launch.packReady
            ? CatalogPack.ready
            : expects
                ? CatalogPack.blocked
                : CatalogPack.missing;
      });
    } catch (_) {
      if (!_alive || !mounted || !identical(_signal, signal)) {
        return;
      }

      setState(() {
        _pack = expects ? CatalogPack.blocked : CatalogPack.missing;
      });
    }
  }

  void _bindNumberFiles(CatalogLaunch launch) {
    final manifest = _pinnedAudio;
    final files = <String, NumberAudioFile>{};

    if (manifest != null) {
      for (final clip in manifest.clips) {
        final path = launch.pathFor(clip.semanticKey);

        if (path == null) {
          continue;
        }

        files[clip.semanticKey] = NumberAudioFile(durationMs: clip.durationMs, path: path);
      }
    }

    setNumberAudioFiles(files);
    setSpeechAudioFiles(
      {
        for (final entry in files.entries)
          entry.key: SpeechAudioFile(
            durationMs: entry.value.durationMs,
            locale: _clipLocale(manifest, entry.key),
            path: entry.value.path,
            text: _clipText(manifest, entry.key),
          ),
      },
      catalogKeys: manifest?.clips.map((clip) => clip.semanticKey).toSet() ?? const {},
    );
  }

  String _clipLocale(ExerciseAudioManifest? manifest, String semanticKey) {
    final clips = manifest?.clips ?? const [];
    for (final clip in clips) {
      if (clip.semanticKey == semanticKey) {
        return clip.locale;
      }
    }
    return '';
  }

  String _clipText(ExerciseAudioManifest? manifest, String semanticKey) {
    final clips = manifest?.clips ?? const [];
    for (final clip in clips) {
      if (clip.semanticKey == semanticKey) {
        return clip.text;
      }
    }
    return '';
  }

  void _retry() {
    _signal?.cancel();
    _launch?.release();
    _launch = null;
    setState(() {
      _attempt += 1;
      _pack = _expectsStimuli ? CatalogPack.preparing : CatalogPack.missing;
    });
    _prepare();
  }

  @override
  Widget build(BuildContext context) {
    final trainerKey = widget.trainerKey;
    final params = widget.params;
    final l10n = widget.l10n;
    final onComplete = widget.onComplete;
    final runtimeSnapshot = widget.runtimeSnapshot;
    final stepChrome = widget.stepChrome;

    if (_pinnedAudio != null && _pinnedAudio!.trainerKey.isEmpty) {
      return _TrainerPlayerError(message: 'Каталог звука без тренажёра.');
    }

    if (!isTrainerKey(trainerKey)) {
      return _TrainerPlayerError(
        message: 'Тренажёр «$trainerKey» не зарегистрирован.',
      );
    }

    final validated = validateTrainerParams(trainerKey, params);
    if (!validated.ok) {
      return _TrainerPlayerError(message: validated.error ?? l10n.requestError);
    }

    final key = TrainerKey.tryParse(trainerKey)!;
    final definition = trainerDefinitions[key]!;
    final builder = trainerBuilders[key];
    final validatedParams = <String, dynamic>{
      ...validated.params!,
      '__runtimeSnapshot': ?runtimeSnapshot,
    };

    final mayStart = catalogTrainerMayStart(_pack);
    final trainerWidget = !mayStart
        ? _CatalogAudioStatus(
            key: ValueKey(_attempt),
            blocked: _pack == CatalogPack.blocked,
            l10n: l10n,
            onRetry: _retry,
          )
        : builder != null
            ? builder(params: validatedParams, onComplete: onComplete)
            : UnimplementedTrainer(
                title: definition.title,
                trainerKey: trainerKey,
                l10n: l10n,
              );
    final chrome = stepChrome == null
        ? null
        : TrainerStepChrome(
            errorMessage: stepChrome.errorMessage,
            finishLabel: stepChrome.finishLabel,
            isInteractive: stepChrome.isInteractive,
            isLast: stepChrome.isLast,
            isPending: stepChrome.isPending || !mayStart,
            nextLabel: stepChrome.nextLabel,
            onAdvance: stepChrome.onAdvance,
            theme: stepChrome.theme,
          );

    return TrainerDirectionThemeScope(
      direction: definition.direction,
      child: TrainerDirectionStage(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: CatalogAudioScope(
                      launch: _launch,
                      child: trainerWidget,
                    ),
                  ),
                  if (chrome != null) TrainerStepChromeBar(chrome: chrome),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TrainerPlayerError extends StatelessWidget {
  const _TrainerPlayerError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 14, color: Color(0xFFB91C1C)),
      ),
    );
  }
}

class _CatalogAudioStatus extends StatelessWidget {
  const _CatalogAudioStatus({
    super.key,
    required this.blocked,
    required this.l10n,
    required this.onRetry,
  });

  final bool blocked;
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              blocked ? l10n.catalogAudioBlocked : l10n.catalogAudioPreparing,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (blocked) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: Text(l10n.catalogAudioRetry)),
            ],
          ],
        ),
      ),
    );
  }
}

class CatalogAudioScope extends InheritedWidget {
  const CatalogAudioScope({required this.launch, required super.child, super.key});

  final CatalogLaunch? launch;

  static CatalogAudioScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CatalogAudioScope>();
  }

  @override
  bool updateShouldNotify(CatalogAudioScope oldWidget) => oldWidget.launch != launch;
}

bool isTrainerInteractive(String trainerKey) {
  return getTrainerDefinition(trainerKey)?.isInteractive ?? false;
}

String trainerTitleForKey(String trainerKey) {
  return getTrainerDefinition(trainerKey)?.title ?? trainerKey;
}
