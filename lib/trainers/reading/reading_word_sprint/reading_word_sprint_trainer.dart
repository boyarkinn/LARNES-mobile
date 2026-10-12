import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_sprint/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingWordSprintTrainer extends StatefulWidget {
  const ReadingWordSprintTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ReadingWordSprintTrainer> createState() => _ReadingWordSprintTrainerState();
}

class _ReadingWordSprintTrainerState extends State<ReadingWordSprintTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  late List<String> _queue;
  late List<String> _sentences;
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
  void didUpdateWidget(ReadingWordSprintTrainer oldWidget) {
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
    final payload = readTrainerRuntimeSnapshot('reading-word-sprint', widget.params);
    final words = payload?['words'];
    final sentences = payload?['sentences'];
    if (words is List && words.isNotEmpty && sentences is List && sentences.isNotEmpty) {
      _queue = words.map((item) => item.toString()).toList();
      _sentences = sentences.map((item) => item.toString()).toList();
    } else {
      final passage = passageById(widget.params['passageId']?.toString() ?? defaultPassageId);
      _queue = [...?passage?.sprint.words];
      _sentences = [...?passage?.sprint.sentences];
    }
    _resetToken = '${_queue.join('|')}::${_sentences.join('|')}';
  }

  void _cancelTimers() {
    _instructionTimer?.cancel();
    _typeTimer?.cancel();
    _instructionTimer = null;
    _typeTimer = null;
  }

  void _armInstruction() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final stepMs = readingSprintInstructionText.isEmpty
        ? readingSprintInstructionMs
        : (readingSprintInstructionMs / readingSprintInstructionText.length).round().clamp(16, 400);
    _typeTimer = Timer.periodic(Duration(milliseconds: reduceMotion ? 16 : stepMs), (timer) {
      if (!mounted) return;
      if (_instructionLength >= readingSprintInstructionText.length) {
        timer.cancel();
        return;
      }
      setState(() => _instructionLength += 1);
    });
    _instructionTimer = Timer(const Duration(milliseconds: readingSprintInstructionMs), () {
      if (!mounted) return;
      setState(() => _phase = 'word');
    });
  }

  void _mark(String mark) {
    final next = readingSprintQueueAfter(_queue, mark);
    setState(() {
      _queue = next;
      if (next.isEmpty) _phase = 'sentences';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(length: _instructionLength, text: readingSprintInstructionText);
    }

    if (_phase == 'sentences') {
      return TrainerScene(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final sentence in _sentences)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    sentence,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(color: Color(0xFF20352D), fontSize: 28, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: widget.onComplete,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF20352D)),
                child: const Text('Дальше'),
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
              _queue.isEmpty ? '' : _queue.first,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Color(0xFF047857), fontSize: 48, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: () => _mark('ok'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF20352D)),
                  child: const Text('Верно'),
                ),
                OutlinedButton(
                  onPressed: () => _mark('miss'),
                  child: const Text('Ошибка'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
