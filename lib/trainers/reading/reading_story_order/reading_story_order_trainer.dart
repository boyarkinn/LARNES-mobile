import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_instruction.dart';
import 'package:larnes_mobile/trainers/reading/reading_story_order/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingStoryOrderTrainer extends StatefulWidget {
  const ReadingStoryOrderTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ReadingStoryOrderTrainer> createState() => _ReadingStoryOrderTrainerState();
}

class _ReadingStoryOrderTrainerState extends State<ReadingStoryOrderTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _instructionSpeech = '';
  void Function()? _cancelInstruction;
  var _placed = 0;
  late List<String> _sentences;
  late List<int> _order;
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
  void didUpdateWidget(ReadingStoryOrderTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _resetToken;
    _readPlan();
    if (previous != _resetToken) {
      _cancelTimers();
      setState(() {
        _phase = 'instruction';
        _instructionLength = 0;
        _placed = 0;
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
    final payload = readTrainerRuntimeSnapshot('reading-story-order', widget.params);
    final sentences = payload?['sentences'];
    final order = payload?['order'];
    if (sentences is List && sentences.length >= 3 && order is List && order.isNotEmpty) {
      _sentences = sentences.map((item) => item.toString()).toList();
      _order = order.map((item) => item is num ? item.toInt() : 0).toList();
    } else {
      final passage = passageById(widget.params['passageId']?.toString() ?? defaultPassageId);
      final count = readingStoryCards(widget.params['storyCards']);
      final available = passage?.story ?? const <String>[];
      final take = count < available.length ? count : available.length;
      _sentences = available.take(take).toList();
      _order = readingStoryOrder(_sentences.length);
    }
    _resetToken = '${_sentences.join('|')}|${_order.join(',')}';
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
      fallbackMs: readingStoryInstructionMs,
      fallbackText: readingStoryInstructionText,
      isMounted: () => mounted,
      onFinished: () {
      if (!mounted) return;
      setState(() => _phase = 'order');
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
      trainerKey: 'reading-story-order',
    );
  }

  void _choose(int index) {
    if (index != _placed) return;
    final next = _placed + 1;
    setState(() {
      _placed = next;
      if (next == _sentences.length) _phase = 'text';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(length: _instructionLength, text: _instructionSpeech.isEmpty ? readingStoryInstructionText : _instructionSpeech);
    }

    if (_phase == 'text') {
      return TrainerScene(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _sentences.join(' '),
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Color(0xFF20352D), fontSize: 26, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: widget.onComplete,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF20352D)),
                child: const Text('Готово'),
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
            for (var index = 0; index < _placed; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _sentences[index],
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(color: Color(0xFF4D7C0F), fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final index in _order)
                  if (index >= _placed)
                    GestureDetector(
                      onTap: () => _choose(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7EEF2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _sentences[index],
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(color: Color(0xFF20352D), fontSize: 18, fontWeight: FontWeight.w600),
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
