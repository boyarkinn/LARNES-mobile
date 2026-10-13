import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_instruction.dart';
import 'package:larnes_mobile/trainers/reading/reading_flash/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

const readingFlashInstructionText = 'Читай вспышку';
const readingFlashInstructionMs = 2400;
const readingFlashGapMs = 400;

class ReadingFlashTrainer extends StatefulWidget {
  const ReadingFlashTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ReadingFlashTrainer> createState() => _ReadingFlashTrainerState();
}

class _ReadingFlashTrainerState extends State<ReadingFlashTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  Timer? _playTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _instructionSpeech = '';
  void Function()? _cancelInstruction;
  var _index = 0;
  var _finished = false;
  late List<String> _chunks;
  late int _durationMs;
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
  void didUpdateWidget(ReadingFlashTrainer oldWidget) {
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
    final payload = readTrainerRuntimeSnapshot('reading-flash', widget.params);
    final text = payload?['text']?.toString() ?? resolvePassageText(widget.params);
    final kind = readingFlashKind(payload?['flashKind'] ?? widget.params['flashKind']);
    final shows = readingFlashShows(payload?['flashShows'] ?? widget.params['flashShows']);
    _durationMs = readingFlashDurationMs(payload?['flashDurationMs'] ?? widget.params['flashDurationMs']);
    _chunks = takeReadingFlashShows(readingFlashChunks(text, kind), shows);
    _resetToken = '$text|$kind|$shows|$_durationMs';
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
      fallbackMs: readingFlashInstructionMs,
      fallbackText: readingFlashInstructionText,
      isMounted: () => mounted,
      onFinished: () {
      if (!mounted) return;
      setState(() => _phase = 'show');
      _armShow();
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
      trainerKey: 'reading-flash',
    );
  }

  void _armShow() {
    _playTimer?.cancel();
    if (_chunks.isEmpty) {
      _finish();
      return;
    }
    _playTimer = Timer(Duration(milliseconds: _durationMs), () {
      if (!mounted) return;
      setState(() => _phase = 'blank');
      _playTimer = Timer(const Duration(milliseconds: readingFlashGapMs), () {
        if (!mounted) return;
        if (_index + 1 >= _chunks.length) {
          _finish();
          return;
        }
        setState(() {
          _index += 1;
          _phase = 'show';
        });
        _armShow();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: _instructionSpeech.isEmpty ? readingFlashInstructionText : _instructionSpeech,
      );
    }

    final text = _phase == 'show' && _index < _chunks.length ? _chunks[_index] : null;
    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: text == null
              ? const SizedBox(height: 64)
              : Text(
                  text,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: Color(0xFF20352D),
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
        ),
      ),
    );
  }
}
