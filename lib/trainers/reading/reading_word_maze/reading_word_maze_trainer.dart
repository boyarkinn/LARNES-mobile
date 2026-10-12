import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_maze/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingWordMazeTrainer extends StatefulWidget {
  const ReadingWordMazeTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ReadingWordMazeTrainer> createState() => _ReadingWordMazeTrainerState();
}

class _ReadingWordMazeTrainerState extends State<ReadingWordMazeTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _step = 0;
  late String _mode;
  late String _rule;
  late List<int> _path;
  late List<String> _words;
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
  void didUpdateWidget(ReadingWordMazeTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _resetToken;
    _readPlan();
    if (previous != _resetToken) {
      _cancelTimers();
      setState(() {
        _phase = 'instruction';
        _instructionLength = 0;
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
    final payload = readTrainerRuntimeSnapshot('reading-word-maze', widget.params);
    final words = payload?['words'];
    final path = payload?['path'];
    if (words is List && words.length == readingMazeCells && path is List && path.length >= 3) {
      _words = words.map((item) => item.toString()).toList();
      _path = path.map((item) => item is num ? item.toInt() : 0).toList();
      _mode = readingMazeMode(payload?['mode']);
      _rule = payload?['rule']?.toString() ?? '';
    } else {
      final passage = passageById(widget.params['passageId']?.toString() ?? defaultPassageId) ??
          passageById(defaultPassageId);
      _mode = readingMazeMode(widget.params['mazeMode']);
      final task = _mode == 'sentence' ? passage?.maze.sentence : passage?.maze.group;
      _words = task?.words ?? const <String>[];
      _path = task?.path ?? const <int>[];
      _rule = task?.rule ?? '';
    }
    _resetToken = '$_mode|${_path.join(',')}|${_words.join('|')}';
  }

  void _cancelTimers() {
    _instructionTimer?.cancel();
    _typeTimer?.cancel();
    _instructionTimer = null;
    _typeTimer = null;
  }

  void _armInstruction() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final stepMs = readingWordMazeInstructionText.isEmpty
        ? readingWordMazeInstructionMs
        : (readingWordMazeInstructionMs / readingWordMazeInstructionText.length).round().clamp(16, 400);
    _typeTimer = Timer.periodic(Duration(milliseconds: reduceMotion ? 16 : stepMs), (timer) {
      if (!mounted) return;
      if (_instructionLength >= readingWordMazeInstructionText.length) {
        timer.cancel();
        return;
      }
      setState(() => _instructionLength += 1);
    });
    _instructionTimer = Timer(const Duration(milliseconds: readingWordMazeInstructionMs), () {
      if (!mounted) return;
      setState(() => _phase = 'play');
    });
  }

  void _choose(int index) {
    if (_step >= _path.length || index != _path[_step]) return;
    final next = _step + 1;
    setState(() => _step = next);
    if (next == _path.length) widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(length: _instructionLength, text: readingWordMazeInstructionText);
    }

    final taken = _path.take(_step).toSet();
    final built = _path.take(_step).map((index) => index < _words.length ? _words[index] : '').join(' ');

    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _rule,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Color(0xFF20352D), fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              built,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Color(0xFF7E22CE), fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (var row = 0; row < 3; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    for (var column = 0; column < 3; column++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _cell(row * 3 + column, taken),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(int index, Set<int> taken) {
    final word = index < _words.length ? _words[index] : '';
    final ok = taken.contains(index);
    return FilledButton(
      onPressed: () => _choose(index),
      style: FilledButton.styleFrom(
        backgroundColor: ok ? const Color(0xFF7E22CE) : const Color(0xFFE7EEF2),
        foregroundColor: ok ? Colors.white : const Color(0xFF20352D),
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      ),
      child: Text(word, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}
