import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_instruction.dart';
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
    required this.trainerKey,
    this.clickOnLetter = false,
    this.note,
    this.beforeFade,
    this.onComplete,
  });

  final String instruction;
  final int letterCount;
  final int letterPauseMs;
  final String resetToken;
  final bool clickOnLetter;
  final String? note;
  final Future<void> Function()? beforeFade;
  final VoidCallback? onComplete;
  final Widget Function(int hiddenOrder) scene;
  final String trainerKey;

  @override
  State<ReadingPassagePlay> createState() => _ReadingPassagePlayState();
}

class _ReadingPassagePlayState extends State<ReadingPassagePlay> {
  Timer? _vanishTimer;
  Timer? _doneTimer;
  void Function()? _cancelInstruction;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _instructionText = '';
  var _hiddenOrder = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _phase != 'instruction' || _cancelInstruction != null) return;
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
    _cancelInstruction?.call();
    _cancelInstruction = null;
    _vanishTimer?.cancel();
    _doneTimer?.cancel();
    _vanishTimer = null;
    _doneTimer = null;
    if (widget.beforeFade != null) {
      unawaited(getSharedClipPlayer().cancel());
    }
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
    _cancelInstruction = startReadingInstruction(
      fallbackMs: readingPassageInstructionMs,
      fallbackText: widget.instruction,
      isMounted: () => mounted,
      onFinished: () {
        if (!mounted) return;
        unawaited(_beginPassage());
      },
      onFrame: (text, length) {
        _instructionText = text;
        _instructionLength = length;
        if (length == 0 || !mounted) {
          return;
        }
        setState(() {});
      },
      reduceMotion: reduceMotion,
      trainerKey: widget.trainerKey,
    );
  }

  Future<void> _beginPassage() async {
    final lead = widget.beforeFade;
    if (lead != null) {
      try {
        await lead();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _phase = 'play');
    _armVanish();
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
        text: _instructionText.isEmpty ? widget.instruction : _instructionText,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.scene(_hiddenOrder),
        if (widget.note != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(
                widget.note!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF155E75), fontSize: 18),
              ),
            ),
          ),
      ],
    );
  }
}
