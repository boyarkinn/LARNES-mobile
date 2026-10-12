import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';

const readingPassageInstructionMs = 2400;

class ReadingPassagePlay extends StatefulWidget {
  const ReadingPassagePlay({
    super.key,
    required this.instruction,
    required this.letterCount,
    required this.letterPauseMs,
    required this.resetToken,
    required this.scene,
    this.clickOnLetter = false,
    this.onComplete,
  });

  final String instruction;
  final int letterCount;
  final int letterPauseMs;
  final String resetToken;
  final bool clickOnLetter;
  final VoidCallback? onComplete;
  final Widget Function(int hiddenOrder) scene;

  @override
  State<ReadingPassagePlay> createState() => _ReadingPassagePlayState();
}

class _ReadingPassagePlayState extends State<ReadingPassagePlay> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  Timer? _vanishTimer;
  Timer? _doneTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _hiddenOrder = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _phase != 'instruction' || _instructionTimer != null) return;
      _armInstruction();
    });
  }

  @override
  void didUpdateWidget(ReadingPassagePlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) {
      _reset();
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _instructionTimer?.cancel();
    _typeTimer?.cancel();
    _vanishTimer?.cancel();
    _doneTimer?.cancel();
    _instructionTimer = null;
    _typeTimer = null;
    _vanishTimer = null;
    _doneTimer = null;
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
    final text = widget.instruction;
    final stepMs = text.isEmpty
        ? readingPassageInstructionMs
        : (readingPassageInstructionMs / text.length).round().clamp(16, 400);
    _typeTimer = Timer.periodic(Duration(milliseconds: reduceMotion ? 16 : stepMs), (timer) {
      if (!mounted) return;
      if (_instructionLength >= text.length) {
        timer.cancel();
        return;
      }
      setState(() => _instructionLength += 1);
    });
    _instructionTimer = Timer(const Duration(milliseconds: readingPassageInstructionMs), () {
      if (!mounted) return;
      setState(() => _phase = 'play');
      _armVanish();
    });
  }

  void _armVanish() {
    if (widget.letterCount == 0) {
      widget.onComplete?.call();
      return;
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    var order = 0;
    _vanishTimer = Timer.periodic(
      Duration(milliseconds: reduceMotion ? 16 : widget.letterPauseMs),
      (timer) {
        if (!mounted) return;
        order += 1;
        setState(() => _hiddenOrder = order);
        if (widget.clickOnLetter && !reduceMotion) {
          SystemSound.play(SystemSoundType.click);
        }
        if (order >= widget.letterCount) {
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
        text: widget.instruction,
      );
    }

    return widget.scene(_hiddenOrder);
  }
}
