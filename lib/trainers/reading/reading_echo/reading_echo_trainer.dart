import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/reading/reading_echo/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/echo_fragment.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_instruction.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingEchoTrainer extends StatefulWidget {
  const ReadingEchoTrainer({super.key, required this.params});

  final Map<String, dynamic> params;

  @override
  State<ReadingEchoTrainer> createState() => _ReadingEchoTrainerState();
}

class _ReadingEchoTrainerState extends State<ReadingEchoTrainer> {
  Timer? _stepTimer;
  void Function()? _cancelInstruction;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _instructionSpeech = '';
  var _narratorMissing = false;
  var _playToken = 0;
  var _step = 0;
  late List<String> _sentences;
  late int _pauseMs;
  late bool _highlight;
  late bool _repeat;
  late String _resetToken;

  @override
  void initState() {
    super.initState();
    _readPlan();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _phase != 'instruction' || _cancelInstruction != null) return;
      _armInstruction();
    });
  }

  @override
  void didUpdateWidget(ReadingEchoTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _resetToken;
    _readPlan();
    if (previous != _resetToken) {
      _cancelTimers();
      setState(() {
        _phase = 'instruction';
        _instructionLength = 0;
        _instructionSpeech = '';
        _narratorMissing = false;
        _step = 0;
      });
      _armInstruction();
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _readPlan() {
    final payload = readTrainerRuntimeSnapshot('reading-echo', widget.params);
    final text = payload?['text']?.toString() ?? resolvePassageText(widget.params);
    final span = readingEchoSpan(payload?['echoSpan'] ?? widget.params['echoSpan']);
    _pauseMs = readingEchoPauseMs(payload?['echoPauseMs'] ?? widget.params['echoPauseMs']);
    _highlight = readingEchoSwitch(payload?['echoHighlight'] ?? widget.params['echoHighlight']) == 'on';
    _repeat = readingEchoSwitch(payload?['echoRepeat'] ?? widget.params['echoRepeat']) == 'on';
    _sentences = readingEchoFragment(text, span);
    _resetToken = '$text|$span|$_pauseMs|$_highlight|$_repeat';
  }

  void _cancelTimers() {
    _cancelInstruction?.call();
    _cancelInstruction = null;
    _stepTimer?.cancel();
    _stepTimer = null;
    _playToken += 1;
    unawaited(getSharedClipPlayer().cancel());
  }

  void _armInstruction() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _cancelInstruction = startReadingInstruction(
      fallbackMs: readingEchoInstructionMs,
      fallbackText: readingEchoInstructionText,
      isMounted: () => mounted,
      onFinished: () {
        if (!mounted) return;
        setState(() {
          _step = 0;
          _narratorMissing = false;
          _phase = 'play';
        });
        _armStep();
      },
      onFrame: (text, length) {
        _instructionSpeech = text;
        _instructionLength = length;
        if (length == 0 || !mounted) {
          return;
        }
        setState(() {});
      },
      reduceMotion: reduceMotion,
      trainerKey: 'reading-echo',
    );
  }

  void _beginPause() {
    _stepTimer?.cancel();
    _stepTimer = Timer(Duration(milliseconds: _pauseMs), () {
      if (!mounted) return;
      setState(() => _step += 1);
      _armStep();
    });
  }

  void _armStep() {
    _stepTimer?.cancel();
    if (_step >= _sentences.length) {
      setState(() => _phase = 'rest');
      return;
    }

    final sentence = _sentences[_step];
    final file = speechAudioFile(echoFragmentAudioKey(sentence));
    if (file == null || file.durationMs <= 0) {
      setState(() => _narratorMissing = true);
      _beginPause();
      return;
    }

    setState(() => _narratorMissing = false);
    final token = _playToken + 1;
    _playToken = token;
    var playbackStarted = false;
    unawaited(getSharedClipPlayer().play([file.path], playbackRate: 1, onStarted: () {
      if (!mounted || token != _playToken || playbackStarted) {
        return;
      }
      playbackStarted = true;
      _stepTimer?.cancel();
      _stepTimer = Timer(Duration(milliseconds: file.durationMs + 400), () {
        if (!mounted || token != _playToken) return;
        _playToken += 1;
        unawaited(getSharedClipPlayer().cancel());
        _beginPause();
      });
    }).then((_) {
      if (!mounted || token != _playToken) return;
      _stepTimer?.cancel();
      _beginPause();
    }));
  }

  void _replay() {
    _stepTimer?.cancel();
    _playToken += 1;
    unawaited(getSharedClipPlayer().cancel());
    final current = _step < _sentences.length ? _step : (_sentences.isEmpty ? 0 : _sentences.length - 1);
    setState(() {
      _step = current;
      _narratorMissing = false;
      _phase = 'play';
    });
    _armStep();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: _instructionSpeech.isEmpty ? readingEchoInstructionText : _instructionSpeech,
      );
    }

    final current = _phase == 'play' && _step < _sentences.length ? _step : null;
    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_narratorMissing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Диктор для этого текста ещё не опубликован',
                    style: TextStyle(color: Color(0xFF155E75), fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              Text.rich(
                TextSpan(
                  children: [
                    for (var index = 0; index < _sentences.length; index++)
                      TextSpan(
                        text: '${_sentences[index]} ',
                        style: TextStyle(
                          backgroundColor: _highlight && index == current ? const Color(0xFFCCFBF1) : null,
                          color: _highlight && index == current ? const Color(0xFF155E75) : const Color(0xFF20352D),
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
              ),
              if (_repeat) ...[
                const SizedBox(height: 28),
                OutlinedButton(
                  onPressed: _replay,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF155E75),
                    side: const BorderSide(color: Color(0xFF155E75)),
                  ),
                  child: const Text('Ещё раз'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
