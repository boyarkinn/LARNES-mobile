import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_instruction.dart';
import 'package:larnes_mobile/trainers/reading/reading_phrases/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingPhrasesTrainer extends StatefulWidget {
  const ReadingPhrasesTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ReadingPhrasesTrainer> createState() => _ReadingPhrasesTrainerState();
}

class _ReadingPhrasesTrainerState extends State<ReadingPhrasesTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  Timer? _holdTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _instructionSpeech = '';
  void Function()? _cancelInstruction;
  var _hiddenCount = 0;
  var _finished = false;
  final _accepted = <int>{};
  late List<String> _phrases;
  late String _mode;
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
  void didUpdateWidget(ReadingPhrasesTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _resetToken;
    _readPlan();
    if (previous != _resetToken) {
      _cancelTimers();
      setState(() {
        _phase = 'instruction';
        _instructionLength = 0;
        _hiddenCount = 0;
        _finished = false;
        _accepted.clear();
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
    final payload = readTrainerRuntimeSnapshot('reading-phrases', widget.params);
    final phrases = payload?['phrases'];
    if (phrases is List && phrases.isNotEmpty) {
      _phrases = phrases.map((item) => item.toString()).toList();
      _mode = readingPhraseMode(payload?['phraseMode']);
    } else {
      final passage = passageById(widget.params['passageId']?.toString() ?? defaultPassageId);
      _phrases = [...?passage?.phrases];
      _mode = readingPhraseMode(widget.params['phraseMode']);
    }
    _resetToken = '$_mode|${_phrases.join('|')}';
  }

  void _cancelTimers() {
    _cancelInstruction?.call();
    _cancelInstruction = null;
    _instructionTimer?.cancel();
    _typeTimer?.cancel();
    _holdTimer?.cancel();
    _instructionTimer = null;
    _typeTimer = null;
    _holdTimer = null;
  }

  void _armInstruction() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _cancelInstruction = startReadingInstruction(
      fallbackMs: readingPhraseInstructionMs,
      fallbackText: readingPhraseInstructionText,
      isMounted: () => mounted,
      onFinished: () {
      if (!mounted) return;
      setState(() => _phase = 'play');
      if (_mode == 'fade') _armHold();
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
      trainerKey: 'reading-phrases',
    );
  }

  void _armHold() {
    _holdTimer?.cancel();
    if (_finished) return;
    _holdTimer = Timer(const Duration(milliseconds: readingPhraseHoldMs), () {
      if (!mounted || _finished) return;
      final boundaryCount = _phrases.length <= 1 ? 0 : _phrases.length - 1;
      if (_hiddenCount >= boundaryCount) {
        _finished = true;
        widget.onComplete?.call();
        return;
      }
      setState(() => _hiddenCount += 1);
      _armHold();
    });
  }

  void _acceptGap(int gap) {
    if (_finished || _accepted.contains(gap)) return;
    final gaps = readingPhraseGaps(_phrases);
    if (!gaps.contains(gap)) return;
    setState(() => _accepted.add(gap));
    if (gaps.every(_accepted.contains)) {
      _finished = true;
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: _instructionSpeech.isEmpty ? readingPhraseInstructionText : _instructionSpeech,
      );
    }

    if (_mode == 'place') {
      final words = readingPhraseWords(_phrases);
      return TrainerScene(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var index = 0; index < words.length; index++) ...[
                  Text(
                    words[index],
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: Color(0xFF20352D),
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (index < words.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => _acceptGap(index),
                        child: Container(
                          width: 14,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _accepted.contains(index) ? const Color(0xFF9F1239) : const Color(0xFFE7EEF2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Text.rich(
            TextSpan(
              children: [
                for (var index = 0; index < _phrases.length; index++) ...[
                  if (index > 0)
                    TextSpan(
                      text: readingPhraseBoundaryVisible(index - 1, _hiddenCount) ? ' / ' : ' ',
                      style: TextStyle(
                        color: readingPhraseBoundaryVisible(index - 1, _hiddenCount)
                            ? const Color(0xFF9F1239)
                            : const Color(0xFF20352D),
                      ),
                    ),
                  TextSpan(text: _phrases[index]),
                ],
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Color(0xFF20352D),
              fontSize: 32,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}
