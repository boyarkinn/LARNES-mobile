import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_instruction.dart';
import 'package:larnes_mobile/trainers/reading/reading_main_idea/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingMainIdeaTrainer extends StatefulWidget {
  const ReadingMainIdeaTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ReadingMainIdeaTrainer> createState() => _ReadingMainIdeaTrainerState();
}

class _ReadingMainIdeaTrainerState extends State<ReadingMainIdeaTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _instructionSpeech = '';
  void Function()? _cancelInstruction;
  late List<String> _choices;
  late int _correctIndex;
  late String _confirm;
  late List<String> _sentences;
  late String _text;
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
  void didUpdateWidget(ReadingMainIdeaTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _resetToken;
    _readPlan();
    if (previous != _resetToken) {
      _cancelTimers();
      setState(() {
        _phase = 'instruction';
        _instructionLength = 0;
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
    final payload = readTrainerRuntimeSnapshot('reading-main-idea', widget.params);
    final choices = payload?['choices'];
    final sentences = payload?['sentences'];
    final confirm = payload?['confirm'];
    final correctIndex = payload?['correctIndex'];
    if (choices is List && choices.length == 3 && sentences is List && sentences.isNotEmpty && confirm is String) {
      _choices = choices.map((item) => item.toString()).toList();
      _sentences = sentences.map((item) => item.toString()).toList();
      _confirm = confirm;
      _correctIndex = correctIndex is num ? correctIndex.toInt() : 0;
      _text = payload?['text']?.toString() ?? _sentences.join(' ');
    } else {
      final passage = passageById(widget.params['passageId']?.toString() ?? defaultPassageId);
      _choices = passage?.idea.choices ?? const <String>[];
      _correctIndex = passage?.idea.correctIndex ?? 0;
      _confirm = passage?.idea.confirm ?? '';
      _text = passage?.text ?? '';
      _sentences = readingMainIdeaSentences(_text);
    }
    _resetToken = '${_text}|${_choices.join('|')}|$_confirm';
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
      fallbackMs: readingMainIdeaInstructionMs,
      fallbackText: readingMainIdeaInstructionText,
      isMounted: () => mounted,
      onFinished: () {
      if (!mounted) return;
      setState(() => _phase = 'choose');
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
      trainerKey: 'reading-main-idea',
    );
  }

  void _choose(int index) {
    if (index != _correctIndex) return;
    setState(() => _phase = 'confirm');
  }

  void _confirmLine(int index) {
    if (index < 0 || index >= _sentences.length || _sentences[index] != _confirm) return;
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(length: _instructionLength, text: _instructionSpeech.isEmpty ? readingMainIdeaInstructionText : _instructionSpeech);
    }

    if (_phase == 'confirm') {
      final picked = _correctIndex >= 0 && _correctIndex < _choices.length ? _choices[_correctIndex] : '';
      return TrainerScene(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                picked,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Color(0xFF6D28D9), fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < _sentences.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton(
                    onPressed: () => _confirmLine(index),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE7EEF2), foregroundColor: const Color(0xFF20352D)),
                    child: Text(_sentences[index], textDirection: TextDirection.ltr),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _text,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Color(0xFF20352D), fontSize: 26, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < _choices.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton(
                  onPressed: () => _choose(index),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE7EEF2), foregroundColor: const Color(0xFF20352D)),
                  child: Text(_choices[index], textDirection: TextDirection.ltr),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
