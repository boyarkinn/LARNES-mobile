import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_pause_scope.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_result_scope.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_button.dart';
import 'package:larnes_mobile/trainers/shared/active_clock.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'reading_instruction.dart';
import 'text_passage_model.dart';
import 'text_passage_display.dart';
import 'passage.dart';
import 'package:larnes_mobile/trainers/audio/narration_player.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';

class TextPassagePlay extends StatefulWidget {
  const TextPassagePlay({
    super.key,
    required this.trainerKey,
    required this.plan,
    required this.instruction,
    this.upsideDown = false,
    this.onComplete,
    this.narration,
  });
  final String trainerKey;
  final TextPassagePlan plan;
  final String instruction;
  final bool upsideDown;
  final VoidCallback? onComplete;
  final NarratedPassage? narration;
  @override
  State<TextPassagePlay> createState() => _TextPassagePlayState();
}

class _TextPassagePlayState extends State<TextPassagePlay> {
  bool _started = false, _loaded = false, _paused = false, _completed = false;
  String _phase = 'instruction', _speech = '';
  int _elapsed = 0, _length = 0, _savedSecond = -1;
  String? _storageKey;
  Timer? _timer;
  ActiveClock? _clock;
  void Function()? _cancelInstruction;
  late List<VanishUnit> _units;
  Future<void> _writes = Future.value();
  final _narrator = NarrationPlayer();
  final _scroll = ScrollController();
  int _playToken = 0;
  bool _narrating = false;
  int get _duration =>
      widget.narration?.durationMs ??
      vanishLetterCount(_units) * widget.plan.letterPauseMs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final paused = TrainerPauseScope.isPaused(context);
    if (!_started) {
      _started = true;
      _paused = paused;
      _storageKey = TrainerResultScope.maybeOf(context)?.storageKey;
      _units = widget.plan.units;
      unawaited(_restore());
    } else if (_paused != paused) {
      _paused = paused;
      if (paused) {
        _stop();
        unawaited(_persist());
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _resume();
        });
      }
    }
  }

  Future<void> _restore() async {
    try {
      final key = _storageKey;
      final saved = key == null
          ? null
          : (await SharedPreferences.getInstance()).getString(key);
      if (saved != null) {
        final raw = jsonDecode(saved);
        if (raw is Map &&
            raw['text'] == widget.plan.text &&
            raw['disappearance'] == widget.plan.disappearance &&
            raw['pause'] == widget.plan.letterPauseMs &&
            raw['half'] == widget.plan.visibleHalf &&
            raw['audioVersionId'] == widget.narration?.audioVersionId &&
            raw['narratorRate'] == widget.narration?.rate &&
            [
              'instruction',
              'reading',
              'failed',
              'finished',
            ].contains(raw['phase'])) {
          _phase = raw['phase'] as String;
          _elapsed = (raw['elapsed'] as num? ?? 0).toInt().clamp(0, _duration);
        }
      }
    } catch (_) {
      /* Optional progress cache. */
    }
    if (!mounted) return;
    setState(() => _loaded = true);
    _resume();
  }

  Future<void> _persist() {
    final key = _storageKey;
    if (key == null) return Future.value();
    final value = jsonEncode({
      'text': widget.plan.text,
      'disappearance': widget.plan.disappearance,
      'pause': widget.plan.letterPauseMs,
      'half': widget.plan.visibleHalf,
      'phase': _phase,
      'elapsed': _elapsed,
      'audioVersionId': widget.narration?.audioVersionId,
      'narratorRate': widget.narration?.rate,
    });
    _writes = _writes.catchError((Object _) {}).then((_) async {
      try {
        await (await SharedPreferences.getInstance()).setString(key, value);
      } catch (_) {
        // An optional local checkpoint must not prevent completion.
      }
    });
    return _writes;
  }

  void _stop() {
    _playToken++;
    if (_narrating) _elapsed = _narrator.positionMs;
    _narrating = false;
    unawaited(_narrator.stop());
    _cancelInstruction?.call();
    _cancelInstruction = null;
    _timer?.cancel();
    _timer = null;
    _elapsed = _clock?.pause() ?? _elapsed;
    _clock = null;
  }

  void _resume() {
    if (!_loaded || _paused) return;
    if (_phase == 'finished') {
      _notifyComplete();
      return;
    }
    if (_phase == 'instruction') {
      _cancelInstruction = startReadingInstruction(
        trainerKey: widget.trainerKey,
        fallbackText: widget.instruction,
        fallbackMs: 2400,
        reduceMotion: MediaQuery.disableAnimationsOf(context),
        isMounted: () => mounted,
        onFrame: (text, length) {
          if (mounted)
            setState(() {
              _speech = text;
              _length = length;
            });
        },
        onFinished: () {
          if (!mounted) return;
          _cancelInstruction = null;
          setState(() => _phase = 'reading');
          unawaited(_persist());
          _resume();
        },
      );
    } else if (_phase == 'reading' && widget.narration != null && !_narrating) {
      final narration = widget.narration!;
      final path = speechPlaybackPath(narration.semanticKey);
      if (path == null) {
        setState(() => _phase = 'failed');
        return;
      }
      final token = ++_playToken;
      _narrating = true;
      unawaited(
        _narrator
            .play(
              path,
              fromMs: _elapsed,
              durationMs: narration.durationMs,
              rate: narration.rate,
              onPosition: (position) {
                if (!mounted || token != _playToken || _paused) return;
                setState(() => _elapsed = position);
                if (position ~/ 1000 != _savedSecond) {
                  _savedSecond = position ~/ 1000;
                  unawaited(_persist());
                }
              },
            )
            .then((played) {
              if (!mounted || token != _playToken || _paused) return;
              _narrating = false;
              if (played) {
                _finish();
              } else {
                setState(() => _phase = 'failed');
                unawaited(_persist());
              }
            }),
      );
    } else if (_phase == 'reading' &&
        widget.narration == null &&
        widget.plan.disappearance &&
        _clock == null) {
      _clock = ActiveClock(_elapsed)..start();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted || _paused) return;
        final elapsed = _clock!.read().clamp(0, _duration);
        setState(() => _elapsed = elapsed);
        if (elapsed ~/ 1000 != _savedSecond) {
          _savedSecond = elapsed ~/ 1000;
          unawaited(_persist());
        }
        if (elapsed >= _duration) _finish();
      });
    }
  }

  void _finish() {
    if (_completed || _paused) return;
    _stop();
    setState(() => _phase = 'finished');
    unawaited(_persist().whenComplete(_notifyComplete));
  }

  void _notifyComplete() {
    if (!mounted || _completed) return;
    _completed = true;
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _stop();
    unawaited(_persist());
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.expand();
    if (_phase == 'instruction')
      return TrainerInstructionScene(
        length: _length,
        text: _speech.isEmpty ? widget.instruction : _speech,
      );
    final locale = Localizations.localeOf(context).languageCode;
    final label = locale == 'ar'
        ? 'انتهيت من القراءة'
        : locale == 'en'
        ? 'Finished reading'
        : 'Прочитал';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Expanded(
            child: TextPassageDisplay(
              units: _units,
              hiddenTextOffset:
                  widget.narration != null && widget.plan.disappearance
                  ? widget.narration!.alignment?.endOffsetAt(_elapsed) ?? 0
                  : null,
              focusTextOffset: widget.narration?.alignment?.endOffsetAt(
                _elapsed,
              ),
              scrollController: widget.narration == null ? null : _scroll,
              hiddenOrder: widget.plan.disappearance
                  ? _elapsed ~/ widget.plan.letterPauseMs
                  : 0,
              visibleHalf: widget.plan.visibleHalf,
              upsideDown: widget.upsideDown,
            ),
          ),
          if (_phase == 'failed') ...[
            const SizedBox(height: 12),
            Text(
              locale == 'en'
                  ? 'Audio playback stopped.'
                  : locale == 'ar'
                  ? 'توقف تشغيل الصوت.'
                  : 'Воспроизведение остановилось.',
            ),
            TrainerPlayButton(
              onPressed: () {
                setState(() => _phase = 'reading');
                _resume();
              },
              child: Text(
                locale == 'en'
                    ? 'Continue'
                    : locale == 'ar'
                    ? 'متابعة'
                    : 'Продолжить',
              ),
            ),
          ],
          if (!widget.plan.disappearance && widget.narration == null) ...[
            const SizedBox(height: 20),
            TrainerPlayButton(
              onPressed: _finish,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
