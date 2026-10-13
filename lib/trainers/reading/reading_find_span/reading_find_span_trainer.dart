import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_instruction.dart';
import 'package:larnes_mobile/trainers/reading/reading_find_span/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingFindSpanTrainer extends StatefulWidget {
  const ReadingFindSpanTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ReadingFindSpanTrainer> createState() => _ReadingFindSpanTrainerState();
}

class _ReadingFindSpanTrainerState extends State<ReadingFindSpanTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _instructionSpeech = '';
  void Function()? _cancelInstruction;
  var _finished = false;
  final _accepted = <int>{};
  late List<String> _words;
  late List<int> _targets;
  late String _prompt;
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
  void didUpdateWidget(ReadingFindSpanTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _resetToken;
    _readPlan();
    if (previous != _resetToken) {
      _cancelTimers();
      setState(() {
        _phase = 'instruction';
        _instructionLength = 0;
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
    final payload = readTrainerRuntimeSnapshot('reading-find-span', widget.params);
    final words = payload?['words'];
    final targets = payload?['targetIndexes'];
    final prompt = payload?['prompt'];
    if (words is List && words.isNotEmpty && targets is List && prompt is String) {
      _words = words.map((item) => item.toString()).toList();
      _targets = targets.map((item) => item is num ? item.toInt() : -1).where((item) => item >= 0).toList();
      _prompt = prompt;
    } else {
      final passage = passageById(widget.params['passageId']?.toString() ?? defaultPassageId);
      final mode = readingFindMode(widget.params['findMode']);
      _words = readingFindWords(passage?.text ?? '');
      _targets = passage == null
          ? <int>[]
          : readingFindTargetIndexes(_words, mode == 'answer' ? passage.find.answer : [passage.find.word]);
      _prompt = passage == null ? '' : (mode == 'answer' ? passage.question.prompt : passage.find.word);
    }
    _resetToken = '$_prompt|${_words.join('|')}|${_targets.join(',')}';
  }

  void _cancelTimers() {
    _cancelInstruction?.call();
    _cancelInstruction = null;
    _instructionTimer?.cancel();
    _typeTimer?.cancel();
    _instructionTimer = null;
    _typeTimer = null;
  }

  void _armInstruction() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _cancelInstruction = startReadingInstruction(
      fallbackMs: readingFindInstructionMs,
      fallbackText: readingFindInstructionText,
      isMounted: () => mounted,
      onFinished: () {
      if (!mounted) return;
      setState(() => _phase = 'play');
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
      trainerKey: 'reading-find-span',
    );
  }

  void _acceptWord(int index) {
    if (_finished || _accepted.contains(index) || !_targets.contains(index)) return;
    setState(() => _accepted.add(index));
    if (_targets.every(_accepted.contains)) {
      _finished = true;
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(length: _instructionLength, text: _instructionSpeech.isEmpty ? readingFindInstructionText : _instructionSpeech);
    }

    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF3730A3), fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < _words.length; index++)
                  GestureDetector(
                    onTap: () => _acceptWord(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accepted.contains(index) ? const Color(0xFF3730A3) : const Color(0xFFE7EEF2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _words[index],
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: _accepted.contains(index) ? const Color(0xFFF8FAFC) : const Color(0xFF20352D),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
