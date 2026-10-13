import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_instruction.dart';
import 'package:larnes_mobile/trainers/reading/reading_cloze/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingClozeTrainer extends StatefulWidget {
  const ReadingClozeTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ReadingClozeTrainer> createState() => _ReadingClozeTrainerState();
}

class _ReadingClozeTrainerState extends State<ReadingClozeTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _instructionSpeech = '';
  void Function()? _cancelInstruction;
  var _finished = false;
  var _accepted = -1;
  late List<String> _choices;
  late int _correctIndex;
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
  void didUpdateWidget(ReadingClozeTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _resetToken;
    _readPlan();
    if (previous != _resetToken) {
      _cancelTimers();
      setState(() {
        _phase = 'instruction';
        _instructionLength = 0;
        _finished = false;
        _accepted = -1;
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
    final payload = readTrainerRuntimeSnapshot('reading-cloze', widget.params);
    final choices = payload?['choices'];
    final prompt = payload?['prompt'];
    final correct = payload?['correctIndex'];
    if (choices is List && choices.length == 3 && prompt is String && correct is num) {
      _choices = choices.map((item) => item.toString()).toList();
      _prompt = prompt;
      _correctIndex = correct.toInt();
    } else {
      final passage = passageById(widget.params['passageId']?.toString() ?? defaultPassageId);
      final task = readingClozeMode(widget.params['clozeMode']) == 'story' ? passage?.cloze.story : passage?.cloze.simple;
      _choices = [...?task?.choices];
      _prompt = task?.prompt ?? '';
      _correctIndex = task?.correctIndex ?? 0;
    }
    _resetToken = '$_prompt|${_choices.join('|')}|$_correctIndex';
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
      fallbackMs: readingClozeInstructionMs,
      fallbackText: readingClozeInstructionText,
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
      trainerKey: 'reading-cloze',
    );
  }

  void _choose(int index) {
    if (_finished || index != _correctIndex) return;
    _finished = true;
    setState(() => _accepted = index);
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(length: _instructionLength, text: _instructionSpeech.isEmpty ? readingClozeInstructionText : _instructionSpeech);
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
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Color(0xFF20352D), fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var index = 0; index < _choices.length; index++)
                  GestureDetector(
                    onTap: () => _choose(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _accepted == index ? const Color(0xFF4338CA) : const Color(0xFFE7EEF2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _choices[index],
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: _accepted == index ? const Color(0xFFF8FAFC) : const Color(0xFF20352D),
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
