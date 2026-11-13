import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_result_scope.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_button.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_pause_scope.dart';
import 'package:larnes_mobile/trainers/shared/active_clock.dart';
import 'package:larnes_mobile/trainers/shared/trainer_ready_countdown.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_time_progress.dart';
import 'package:larnes_mobile/trainers/shared/trainer_result_comparison.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/audio/number_bank.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import '../shared/timed_word_session.dart';
import '../shared/reading_word_display.dart';
import '../shared/reading_instruction.dart';
import 'model.dart';

class ReadingMarathonTrainer extends StatefulWidget {
  const ReadingMarathonTrainer({
    super.key,
    required this.params,
    this.onComplete,
    this.playCues,
    this.clockNow,
  });
  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  /// Test/native-host adapter; normal launches always use the shared catalog player.
  final Future<bool> Function(List<String> keys)? playCues;
  final int Function()? clockNow;
  @override
  State<ReadingMarathonTrainer> createState() => _ReadingMarathonState();
}

class _ReadingMarathonState extends State<ReadingMarathonTrainer>
    with WidgetsBindingObserver {
  List<String> _words = [];
  TimedWordSession? _state;
  TrainerResultScope? _scope;
  ActiveClock? _clock;
  Timer? _timer;
  void Function()? _cancelFinalText;
  void Function()? _cancelInstruction;
  final _player = ClipPlayer();
  Future<void> _writes = Future.value();
  String _instruction = '';
  int _length = 0, _generation = 0;
  bool _loading = false,
      _loaded = false,
      _menuPaused = false,
      _appPaused = false,
      _audioFailed = false,
      _saved = false,
      _saveFailed = false,
      _saving = false,
      _voiceDone = false,
      _completed = false;
  String get _lang => Localizations.localeOf(context).languageCode;
  String get _audioLocale => numberAudioLocale;
  String copy(String ru, String en, String ar) => _lang == 'ar'
      ? ar
      : _lang == 'en'
      ? en
      : ru;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final paused = TrainerPauseScope.isPaused(context);
    if (paused != _menuPaused) {
      _menuPaused = paused;
      _syncClock();
    }
    if (_loaded || _loading) return;
    _loading = true;
    _scope = TrainerResultScope.maybeOf(context);
    final payload = readTrainerRuntimeSnapshot(
      'reading-marathon',
      widget.params,
    );
    _words = (payload?['words'] as List? ?? []).whereType<String>().toList();
    if (_words.isNotEmpty) {
      _state = TimedWordSession.create(
        _words.length,
        Random().nextInt(0x100000000),
        4,
      );
    }
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      final key = _scope?.storageKey;
      final raw = key == null
          ? null
          : (await SharedPreferences.getInstance()).getString(key);
      if (raw != null) {
        _state =
            TimedWordSession.restore(
              jsonDecode(raw),
              _words.length,
              marathonDurations,
            ) ??
            _state;
      }
    } catch (_) {
      /* optional checkpoint */
    }
    if (!mounted) return;
    setState(() => _loaded = true);
    final state = _state;
    if (state == null) return;
    if (state.phase == 'intro') {
      _cancelInstruction = startReadingInstruction(
        trainerKey: 'reading-marathon',
        fallbackText: marathonInstruction,
        fallbackMs: 9000,
        reduceMotion: MediaQuery.disableAnimationsOf(context),
        isMounted: () => mounted,
        onFrame: (text, length) {
          if (mounted) {
            setState(() {
              _instruction = text;
              _length = length;
            });
          }
        },
        onFinished: () {
          if (mounted && _state?.phase == 'intro') {
            _apply(_state!.copy(phase: 'ready'));
          }
        },
      );
    } else {
      _syncClock();
      if (state.phase == 'prompt' || state.phase == 'result') {
        unawaited(_narrate());
      }
      if (state.phase == 'result') unawaited(_save());
    }
  }

  void _persist() {
    final key = _scope?.storageKey;
    if (key == null || _state == null) return;
    final raw = jsonEncode(_state!.toJson());
    _writes = _writes
        .catchError((Object _) {})
        .then((_) async {
          await (await SharedPreferences.getInstance()).setString(key, raw);
        })
        .catchError((Object _) {});
  }

  void _apply(TimedWordSession next, {bool persist = true}) {
    if (!mounted) return;
    final previous = _state;
    setState(() => _state = next);
    if (persist) _persist();
    _syncClock();
    if (previous?.phase != next.phase) {
      if (next.phase == 'prompt' || next.phase == 'result') {
        unawaited(_narrate());
      }
      if (next.phase == 'result') unawaited(_save());
    }
  }

  void _syncClock() {
    final state = _state;
    if (!_loaded || state == null) return;
    if (state.phase == 'reading' && !_menuPaused && !_appPaused) {
      if (_clock != null) return;
      _clock = ActiveClock(state.elapsedMs, now: widget.clockNow)..start();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final value = _state;
        if (value?.phase != 'reading' || _clock == null) return;
        final next = value!.tick(_clock!.read(), marathonDurations);
        _apply(
          next,
          persist:
              next.phase != 'reading' ||
              next.elapsedMs ~/ 1000 != value.elapsedMs ~/ 1000,
        );
      });
    } else {
      _timer?.cancel();
      _timer = null;
      final clock = _clock;
      _clock = null;
      if (clock != null && state.phase == 'reading') {
        _apply(state.tick(clock.pause(), marathonDurations));
      } else {
        clock?.pause();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    _appPaused = state != AppLifecycleState.resumed;
    _syncClock();
  }

  Future<void> _narrate() async {
    final state = _state;
    if (state == null) return;
    if (state.phase == 'prompt') {
      _cancelInstruction?.call();
      final key = marathonPrompts[state.round - 1];
      _cancelInstruction = startReadingInstruction(
        trainerKey: 'reading-marathon',
        semanticKey: key,
        fallbackText: marathonCueText(key, _lang),
        fallbackMs: 5000,
        reduceMotion: MediaQuery.disableAnimationsOf(context),
        isMounted: () => mounted,
        onFrame: (text, length) {
          if (mounted) {
            setState(() {
              _instruction = text;
              _length = length;
            });
          }
        },
        onFinished: () {
          if (mounted && _state?.phase == 'prompt') {
            _apply(_state!.copy(phase: 'ready'));
          }
        },
        playbackOverride: widget.playCues == null
            ? null
            : () async {
                await widget.playCues!([key]);
              },
      );
      return;
    }
    final generation = ++_generation;
    setState(() {
      _audioFailed = false;
      _voiceDone = false;
    });
    final keys = marathonFinalKeys(state.counts, _audioLocale);
    final finalText = marathonFinalText(state.counts, _lang);
    final duration =
        keys?.fold<int>(
          0,
          (sum, key) =>
              sum +
              (numberAudioFileForKey(key)?.durationMs ??
                  speechAudioFile(key)?.durationMs ??
                  0),
        ) ??
        0;
    _cancelFinalText?.call();
    _cancelFinalText = startReadingInstructionText(
      text: finalText,
      durationMs: duration > 0 ? duration : 12000,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
      isMounted: () => mounted,
      onFrame: (text, length) {
        if (mounted) {
          setState(() {
            _instruction = text;
            _length = length;
          });
        }
      },
    );
    var success = false;
    if (keys == null) {
      await _player.waitForFallback(const Duration(seconds: 12));
      success = true;
    } else if (widget.playCues != null) {
      success = await widget.playCues!(keys);
    } else {
      final paths = keys
          .map(
            (key) =>
                numberAudioFileForKey(key)?.path ?? speechPlaybackPath(key),
          )
          .toList();
      if (paths.every((path) => path != null)) {
        await _player.play(paths.cast<String>(), playbackRate: 1);
        success = _player.lastPlaybackSucceeded;
      }
    }
    if (!mounted || generation != _generation) return;
    if (!success) {
      setState(() => _audioFailed = true);
      return;
    }
    _cancelFinalText?.call();
    setState(() {
      _voiceDone = true;
      _length = finalText.length;
    });
    _completeIfReady();
  }

  Future<void> _save() async {
    final state = _state;
    if (state?.phase != 'result' || _saving || _saved) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await _writes;
      if (!mounted) return;
      await _scope?.save(context, {
        'kind': 'reading-marathon',
        'orderSeed': state!.orderSeed,
        'rounds': [
          for (var i = 0; i < 4; i++)
            {
              'durationSec': marathonDurations[i] ~/ 1000,
              'wordsRead': state.counts[i],
            },
        ],
      });
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        _completeIfReady();
      }
    }
  }

  void _completeIfReady() {
    if (_saved && _voiceDone && !_completed) {
      _completed = true;
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _timer?.cancel();
    _cancelInstruction?.call();
    _cancelFinalText?.call();
    unawaited(_player.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final state = _state;
    if (state == null) {
      return Center(
        child: Text(
          copy(
            'В выбранной подтеме нет русских слов.',
            'There are no Russian words in this subtopic.',
            'لا توجد كلمات روسية في هذا الموضوع الفرعي.',
          ),
        ),
      );
    }
    if (state.phase == 'intro' || state.phase == 'prompt') {
      return TrainerInstructionScene(length: _length, text: _instruction);
    }
    if (state.phase == 'ready') {
      return TrainerReadyCountdown(
        key: ValueKey(state.round),
        onComplete: () {
          final current = _state;
          if (current?.phase == 'ready') {
            _apply(current!.copy(phase: 'reading', elapsedMs: 0));
          }
        },
      );
    }
    Widget button(String label, VoidCallback onPressed) => TrainerPlayButton(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onPressed: onPressed,
      child: Text(label),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.phase == 'reading') ...[
                  ReadingWordDisplay(word: _words[state.wordIndex]),
                  const SizedBox(height: 32),
                  button(copy('Далее', 'Next', 'التالي'), () {
                    final current = _state;
                    if (!_menuPaused &&
                        !_appPaused &&
                        current?.phase == 'reading') {
                      _apply(
                        current!.confirm(
                          _clock?.read() ?? current.elapsedMs,
                          marathonDurations,
                        ),
                      );
                    }
                  }),
                ] else if (state.phase == 'result') ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: TrainerInstructionText(
                      text: _instruction,
                      length: _length,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: TrainerResultComparison(
                      first: state.counts[0],
                      last: state.counts[3],
                      firstLabel: copy(
                        'Первая минута',
                        'First minute',
                        'الدقيقة الأولى',
                      ),
                      lastLabel: copy(
                        'Последняя минута',
                        'Last minute',
                        'الدقيقة الأخيرة',
                      ),
                    ),
                  ),
                  if (_saving) const CircularProgressIndicator(),
                  if (_saveFailed) ...[
                    Text(
                      copy(
                        'Не удалось сохранить результат.',
                        'Could not save the result.',
                        'تعذّر حفظ النتيجة.',
                      ),
                    ),
                    button(
                      copy(
                        'Повторить сохранение',
                        'Retry saving',
                        'أعد محاولة الحفظ',
                      ),
                      () => unawaited(_save()),
                    ),
                  ],
                ],
                if (_audioFailed) ...[
                  Text(
                    copy(
                      'Не удалось воспроизвести пояснение.',
                      'Could not play the announcement.',
                      'تعذّر تشغيل التوضيح.',
                    ),
                  ),
                  button(
                    copy('Повторить озвучку', 'Retry audio', 'أعد تشغيل الصوت'),
                    () => unawaited(_narrate()),
                  ),
                ],
              ],
            ),
          ),
        ),
        TrainerTimeProgress(
          value: state.phase == 'reading'
              ? state.elapsedMs / marathonDurations[state.round]
              : null,
        ),
      ],
    );
  }
}
