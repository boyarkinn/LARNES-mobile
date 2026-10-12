import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/reading_echo/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingEchoTrainer extends StatefulWidget {
  const ReadingEchoTrainer({super.key, required this.params});

  final Map<String, dynamic> params;

  @override
  State<ReadingEchoTrainer> createState() => _ReadingEchoTrainerState();
}

class _ReadingEchoTrainerState extends State<ReadingEchoTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  Timer? _stepTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _step = 0;
  late List<String> _sentences;
  late int _pauseMs;
  late bool _highlight;
  late bool _repeat;
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
  void didUpdateWidget(ReadingEchoTrainer oldWidget) {
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
    final payload = readTrainerRuntimeSnapshot('reading-echo', widget.params);
    final text = payload?['text']?.toString() ?? resolvePassageText(widget.params);
    final span = readingEchoSpan(payload?['echoSpan'] ?? widget.params['echoSpan']);
    _pauseMs = readingEchoPauseMs(payload?['echoPauseMs'] ?? widget.params['echoPauseMs']);
    _highlight = readingEchoSwitch(payload?['echoHighlight'] ?? widget.params['echoHighlight']) == 'on';
    _repeat = readingEchoSwitch(payload?['echoRepeat'] ?? widget.params['echoRepeat']) == 'on';
    _sentences = readingEchoFragment(text, span);
    _resetToken = '$text|$span|$_pauseMs|$_highlight|$_repeat';
  }

  void _cancelTimers() {
    _instructionTimer?.cancel();
    _typeTimer?.cancel();
    _stepTimer?.cancel();
    _instructionTimer = null;
    _typeTimer = null;
    _stepTimer = null;
  }

  void _armInstruction() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final stepMs = readingEchoInstructionText.isEmpty
        ? readingEchoInstructionMs
        : (readingEchoInstructionMs / readingEchoInstructionText.length).round().clamp(16, 400);
    _typeTimer = Timer.periodic(Duration(milliseconds: reduceMotion ? 16 : stepMs), (timer) {
      if (!mounted) return;
      if (_instructionLength >= readingEchoInstructionText.length) {
        timer.cancel();
        return;
      }
      setState(() => _instructionLength += 1);
    });
    _instructionTimer = Timer(const Duration(milliseconds: readingEchoInstructionMs), () {
      if (!mounted) return;
      setState(() {
        _step = 0;
        _phase = 'play';
      });
      _armStep();
    });
  }

  void _armStep() {
    _stepTimer?.cancel();
    if (_step >= _sentences.length) {
      setState(() => _phase = 'rest');
      return;
    }
    _stepTimer = Timer(Duration(milliseconds: _pauseMs), () {
      if (!mounted) return;
      setState(() => _step += 1);
      _armStep();
    });
  }

  void _replay() {
    _stepTimer?.cancel();
    setState(() {
      _step = 0;
      _phase = 'play';
    });
    _armStep();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: readingEchoInstructionText,
      );
    }

    final current = _phase == 'play' && _step < _sentences.length ? _step : null;
    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    for (var index = 0; index < _sentences.length; index++)
                      TextSpan(
                        text: '${_sentences[index]} ',
                        style: TextStyle(
                          backgroundColor: _highlight && index == current ? const Color(0xFFCCFBF1) : null,
                          color: _highlight && index == current ? const Color(0xFF155E75) : const Color(0xFF20352D),
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
              ),
              if (_repeat) ...[
                const SizedBox(height: 28),
                OutlinedButton(
                  onPressed: _replay,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF155E75),
                    side: const BorderSide(color: Color(0xFF155E75)),
                  ),
                  child: const Text('Ещё раз'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
