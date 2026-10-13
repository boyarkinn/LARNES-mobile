import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_instruction.dart';
import 'package:larnes_mobile/trainers/reading/reading_blocks/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_line_pace/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_line_pace/reading_line_pace_scene.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';

const readingLinePaceInstructionMs = 2400;

class ReadingLinePaceTrainer extends StatefulWidget {
  const ReadingLinePaceTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ReadingLinePaceTrainer> createState() => _ReadingLinePaceTrainerState();
}

class _ReadingLinePaceTrainerState extends State<ReadingLinePaceTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  Timer? _lineTimer;
  Timer? _doneTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _instructionSpeech = '';
  void Function()? _cancelInstruction;
  var _index = 0;
  var _finished = false;
  late List<String> _lines;
  late String _lineKeep;
  late int _linePaceMs;
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
  void didUpdateWidget(ReadingLinePaceTrainer oldWidget) {
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
    final payload = readTrainerRuntimeSnapshot('reading-line-pace', widget.params);
    final text = payload?['text']?.toString() ?? resolvePassageText(widget.params);
    final words = readingBlocksWordsPerLine(payload?['wordsPerLine'] ?? widget.params['wordsPerLine']);
    _lineKeep = readingLineKeep(payload?['lineKeep'] ?? widget.params['lineKeep']);
    _linePaceMs = readingLinePaceMs(payload?['linePaceMs'] ?? widget.params['linePaceMs']);
    _lines = readingLinePaceLines(text, words);
    _resetToken = '$text|$words|$_lineKeep|$_linePaceMs';
  }

  void _cancelTimers() {
    _cancelInstruction?.call();
    _cancelInstruction = null;
    _instructionTimer?.cancel();
    _typeTimer?.cancel();
    _lineTimer?.cancel();
    _doneTimer?.cancel();
    _instructionTimer = null;
    _typeTimer = null;
    _lineTimer = null;
    _doneTimer = null;
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onComplete?.call();
  }

  void _armInstruction() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _cancelInstruction = startReadingInstruction(
      fallbackMs: readingLinePaceInstructionMs,
      fallbackText: readingLinePaceInstructionText,
      isMounted: () => mounted,
      onFinished: () {
      if (!mounted) return;
      setState(() => _phase = 'play');
      _armLines();
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
      trainerKey: 'reading-line-pace',
    );
  }

  void _armLines() {
    if (_lines.isEmpty) {
      _finish();
      return;
    }

    var lineIndex = 0;
    _lineTimer = Timer.periodic(Duration(milliseconds: _linePaceMs), (timer) {
      if (!mounted) return;
      lineIndex += 1;
      if (lineIndex >= _lines.length) {
        timer.cancel();
        _doneTimer = Timer(const Duration(milliseconds: 320), () {
          if (!mounted) return;
          _finish();
        });
        return;
      }
      setState(() => _index = lineIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: _instructionSpeech.isEmpty ? readingLinePaceInstructionText : _instructionSpeech,
      );
    }

    return ReadingLinePaceScene(
      index: _index,
      lineKeep: _lineKeep,
      lines: _lines,
    );
  }
}
