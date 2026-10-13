import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_instruction.dart';
import 'package:larnes_mobile/trainers/reading/reading_fixation/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

const readingFixationInstructionText = 'Читай в одной точке';
const readingFixationInstructionMs = 2400;

class ReadingFixationTrainer extends StatefulWidget {
  const ReadingFixationTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ReadingFixationTrainer> createState() => _ReadingFixationTrainerState();
}

class _ReadingFixationTrainerState extends State<ReadingFixationTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  Timer? _playTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _instructionSpeech = '';
  void Function()? _cancelInstruction;
  var _index = 0;
  var _finished = false;
  late List<String> _fragments;
  late int _pauseMs;
  late String _resetToken;

  @override
  void initState() {
    super.initState();
    _readPlan();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _phase != 'instruction' || _instructionTimer != null) return;
      _armInstruction();
    });
  }

  @override
  void didUpdateWidget(ReadingFixationTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _resetToken;
    _readPlan();
    if (previous != _resetToken) {
      _cancelTimers();
      _finished = false;
      setState(() {
        _phase = 'instruction';
        _instructionLength = 0;
        _index = 0;
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
    final payload = readTrainerRuntimeSnapshot('reading-fixation', widget.params);
    final text = payload?['text']?.toString() ?? resolvePassageText(widget.params);
    final fragment = readingFixationFragment(payload?['fixationFragment'] ?? widget.params['fixationFragment']);
    _pauseMs = readingFixationPauseMs(payload?['fixationPauseMs'] ?? widget.params['fixationPauseMs']);
    _fragments = readingFixationFragments(text, fragment);
    _resetToken = '$text|$fragment|$_pauseMs';
  }

  void _cancelTimers() {
    _cancelInstruction?.call();
    _cancelInstruction = null;
    _instructionTimer?.cancel();
    _typeTimer?.cancel();
    _playTimer?.cancel();
    _instructionTimer = null;
    _typeTimer = null;
    _playTimer = null;
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onComplete?.call();
  }

  void _armInstruction() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _cancelInstruction = startReadingInstruction(
      fallbackMs: readingFixationInstructionMs,
      fallbackText: readingFixationInstructionText,
      isMounted: () => mounted,
      onFinished: () {
      if (!mounted) return;
      setState(() => _phase = 'play');
      _armFragment();
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
      trainerKey: 'reading-fixation',
    );
  }

  void _armFragment() {
    _playTimer?.cancel();
    if (_fragments.isEmpty) {
      _finish();
      return;
    }
    _playTimer = Timer(Duration(milliseconds: _pauseMs), () {
      if (!mounted) return;
      if (_index + 1 >= _fragments.length) {
        _finish();
        return;
      }
      setState(() => _index += 1);
      _armFragment();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: _instructionSpeech.isEmpty ? readingFixationInstructionText : _instructionSpeech,
      );
    }

    final text = _index < _fragments.length ? _fragments[_index] : '';
    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Color(0xFF20352D),
              fontSize: 48,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
