import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/reading_shutter/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_shutter/reading_shutter_scene.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';

const readingShutterInstructionText = 'Читай, часть текста закрыта';
const readingShutterInstructionMs = 2400;

class ReadingShutterTrainer extends StatefulWidget {
  const ReadingShutterTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ReadingShutterTrainer> createState() => _ReadingShutterTrainerState();
}

class _ReadingShutterTrainerState extends State<ReadingShutterTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  Timer? _vanishTimer;
  Timer? _doneTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _hiddenOrder = 0;
  late ReadingShutterPlan _plan;

  @override
  void initState() {
    super.initState();
    _plan = _readPlan();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _phase != 'instruction' || _instructionTimer != null) return;
      _armInstruction();
    });
  }

  @override
  void didUpdateWidget(ReadingShutterTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _readPlan();
    if (next.text != _plan.text ||
        next.letterPauseMs != _plan.letterPauseMs ||
        next.edge != _plan.edge ||
        next.cover != _plan.cover) {
      _plan = next;
      _reset();
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  ReadingShutterPlan _readPlan() {
    final frozen = readingShutterPlanFromSnapshot(
      readTrainerRuntimeSnapshot('reading-shutter', widget.params),
    );
    return frozen ?? readingShutterPlanFromParams(widget.params);
  }

  void _cancelTimers() {
    _instructionTimer?.cancel();
    _typeTimer?.cancel();
    _vanishTimer?.cancel();
    _doneTimer?.cancel();
  }

  void _reset() {
    _cancelTimers();
    setState(() {
      _phase = 'instruction';
      _instructionLength = 0;
      _hiddenOrder = 0;
    });
    _armInstruction();
  }

  void _armInstruction() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final stepMs = readingShutterInstructionText.isEmpty
        ? readingShutterInstructionMs
        : (readingShutterInstructionMs / readingShutterInstructionText.length).round().clamp(16, 400);
    _typeTimer = Timer.periodic(Duration(milliseconds: reduceMotion ? 16 : stepMs), (timer) {
      if (!mounted) return;
      if (_instructionLength >= readingShutterInstructionText.length) {
        timer.cancel();
        return;
      }
      setState(() => _instructionLength += 1);
    });
    _instructionTimer = Timer(const Duration(milliseconds: readingShutterInstructionMs), () {
      if (!mounted) return;
      setState(() => _phase = 'play');
      _armVanish();
    });
  }

  void _armVanish() {
    if (_plan.letterCount == 0) {
      widget.onComplete?.call();
      return;
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    var order = 0;
    _vanishTimer = Timer.periodic(
      Duration(milliseconds: reduceMotion ? 16 : _plan.letterPauseMs),
      (timer) {
        if (!mounted) return;
        order += 1;
        setState(() => _hiddenOrder = order);
        if (order >= _plan.letterCount) {
          timer.cancel();
          _doneTimer = Timer(Duration(milliseconds: reduceMotion ? 16 : 320), () {
            if (!mounted) return;
            widget.onComplete?.call();
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: readingShutterInstructionText,
      );
    }

    return ReadingShutterScene(
      hiddenOrder: _hiddenOrder,
      plan: _plan,
    );
  }
}
