import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/reading_tree/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

const readingTreeInstructionText = 'Читай по ёлочке';
const readingTreeInstructionMs = 2400;

class ReadingTreeTrainer extends StatefulWidget {
  const ReadingTreeTrainer({super.key, required this.params});

  final Map<String, dynamic> params;

  @override
  State<ReadingTreeTrainer> createState() => _ReadingTreeTrainerState();
}

class _ReadingTreeTrainerState extends State<ReadingTreeTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  late List<String> _lines;
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
  void didUpdateWidget(ReadingTreeTrainer oldWidget) {
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
    final payload = readTrainerRuntimeSnapshot('reading-tree', widget.params);
    final text = payload?['text']?.toString() ?? resolvePassageText(widget.params);
    _lines = readingTreeLines(text);
    _resetToken = text;
  }

  void _cancelTimers() {
    _instructionTimer?.cancel();
    _typeTimer?.cancel();
    _instructionTimer = null;
    _typeTimer = null;
  }

  void _armInstruction() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final stepMs = readingTreeInstructionText.isEmpty
        ? readingTreeInstructionMs
        : (readingTreeInstructionMs / readingTreeInstructionText.length).round().clamp(16, 400);
    _typeTimer = Timer.periodic(Duration(milliseconds: reduceMotion ? 16 : stepMs), (timer) {
      if (!mounted) return;
      if (_instructionLength >= readingTreeInstructionText.length) {
        timer.cancel();
        return;
      }
      setState(() => _instructionLength += 1);
    });
    _instructionTimer = Timer(const Duration(milliseconds: readingTreeInstructionMs), () {
      if (!mounted) return;
      setState(() => _phase = 'play');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: readingTreeInstructionText,
      );
    }

    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 2,
                    child: ColoredBox(color: Color(0xFFB7C4BE)),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final line in _lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        line,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
