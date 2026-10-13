import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_instruction.dart';
import 'package:larnes_mobile/trainers/reading/reading_reread/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

const readingRereadInstructionText = 'Читай вслух два раза';
const readingRereadInstructionMs = 2400;

class ReadingRereadTrainer extends StatefulWidget {
  const ReadingRereadTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ReadingRereadTrainer> createState() => _ReadingRereadTrainerState();
}

class _ReadingRereadTrainerState extends State<ReadingRereadTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  Timer? _clockTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _instructionSpeech = '';
  void Function()? _cancelInstruction;
  var _round = 0;
  var _elapsedMs = 0;
  var _errors = 0;
  var _running = false;
  var _stopped = false;
  var _selectedIndex = -1;
  var _finished = false;
  ReadingRereadAttempt? _first;
  ReadingRereadAttempt? _second;
  late String _text;
  ReadingPassageQuestion? _question;
  late String _resetToken;
  var _accumulatedMs = 0;
  DateTime? _startedAt;

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
  void didUpdateWidget(ReadingRereadTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _resetToken;
    _readPlan();
    if (previous != _resetToken) {
      _cancelTimers();
      _finished = false;
      setState(() {
        _phase = 'instruction';
        _instructionLength = 0;
        _resetAttempt();
        _round = 0;
        _first = null;
        _second = null;
        _selectedIndex = -1;
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
    final payload = readTrainerRuntimeSnapshot('reading-reread', widget.params);
    _text = payload?['text']?.toString() ?? resolvePassageText(widget.params);
    if (payload != null && payload.containsKey('question')) {
      _question = readingRereadQuestionFromPayload(payload['question']);
    } else if (widget.params['source'] == 'custom') {
      _question = null;
    } else {
      _question = passageById(widget.params['passageId']?.toString() ?? defaultPassageId)?.question;
    }
    _resetToken = '$_text|${_question?.prompt ?? ''}';
  }

  void _cancelTimers() {
    _cancelInstruction?.call();
    _cancelInstruction = null;
    _instructionTimer?.cancel();
    _typeTimer?.cancel();
    _clockTimer?.cancel();
    _instructionTimer = null;
    _typeTimer = null;
    _clockTimer = null;
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onComplete?.call();
  }

  void _armInstruction() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _cancelInstruction = startReadingInstruction(
      fallbackMs: readingRereadInstructionMs,
      fallbackText: readingRereadInstructionText,
      isMounted: () => mounted,
      onFinished: () {
      if (!mounted) return;
      setState(() => _phase = 'read');
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
      trainerKey: 'reading-reread',
    );
  }

  void _resetAttempt() {
    _clockTimer?.cancel();
    _accumulatedMs = 0;
    _startedAt = null;
    _elapsedMs = 0;
    _errors = 0;
    _running = false;
    _stopped = false;
  }

  void _start() {
    if (_running) return;
    _startedAt = DateTime.now();
    _running = true;
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _startedAt == null) return;
      setState(() {
        _elapsedMs = _accumulatedMs + DateTime.now().difference(_startedAt!).inMilliseconds;
      });
    });
    setState(() {});
  }

  void _stop() {
    if (!_running || _startedAt == null) return;
    _accumulatedMs += DateTime.now().difference(_startedAt!).inMilliseconds;
    _startedAt = null;
    _clockTimer?.cancel();
    setState(() {
      _elapsedMs = _accumulatedMs;
      _running = false;
      _stopped = true;
    });
  }

  void _commit() {
    final attempt = ReadingRereadAttempt(elapsedMs: _accumulatedMs, errors: _errors);
    if (_round == 0) {
      setState(() {
        _first = attempt;
        _phase = 'between';
      });
      return;
    }
    setState(() {
      _second = attempt;
      _phase = 'compare';
    });
  }

  Widget _button(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF20352D),
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(length: _instructionLength, text: _instructionSpeech.isEmpty ? readingRereadInstructionText : _instructionSpeech);
    }

    if (_phase == 'read') {
      return TrainerScene(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _text,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Color(0xFF20352D), fontSize: 32, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Text(
                '${formatReadingRereadSeconds(_elapsedMs)} с',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF20352D)),
              ),
              Text(
                'ошибок: $_errors',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF20352D)),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  _button(_running ? 'Стоп' : 'Старт', _running ? _stop : _start),
                  _button('Ошибка', () => setState(() => _errors += 1)),
                  if (_stopped && !_running) _button('Дальше', _commit),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_phase == 'between' && _first != null) {
      final first = _first!;
      return TrainerScene(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Первый раз', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Color(0xFF20352D))),
            Text('${formatReadingRereadSeconds(first.elapsedMs)} с', style: const TextStyle(fontSize: 24, color: Color(0xFF20352D))),
            Text('ошибок: ${first.errors}', style: const TextStyle(fontSize: 24, color: Color(0xFF20352D))),
            const SizedBox(height: 16),
            _button('Ещё раз', () {
              setState(() {
                _resetAttempt();
                _round = 1;
                _phase = 'read';
              });
            }),
          ],
        ),
      );
    }

    if (_phase == 'compare' && _first != null && _second != null) {
      final gap = describeReadingRereadGap(_first!, _second!);
      return TrainerScene(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Второй раз', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Color(0xFF20352D))),
            Text(gap.time, style: const TextStyle(fontSize: 24, color: Color(0xFF20352D))),
            Text(gap.errors, style: const TextStyle(fontSize: 24, color: Color(0xFF20352D))),
            const SizedBox(height: 16),
            _button(_question == null ? 'Дальше' : 'К вопросу', () {
              if (_question == null) {
                _finish();
                return;
              }
              setState(() => _phase = 'question');
            }),
          ],
        ),
      );
    }

    final question = _question;
    if (_phase == 'question' && question != null) {
      return TrainerScene(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(question.prompt, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF20352D))),
              const SizedBox(height: 16),
              for (var index = 0; index < question.choices.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _button(
                    _selectedIndex < 0
                        ? question.choices[index]
                        : index == question.correctIndex
                            ? '${question.choices[index]} · верно'
                            : index == _selectedIndex
                                ? '${question.choices[index]} · неверно'
                                : question.choices[index],
                    () {
                      if (_selectedIndex >= 0) return;
                      setState(() => _selectedIndex = index);
                    },
                  ),
                ),
              if (_selectedIndex >= 0) _button('Дальше', _finish),
            ],
          ),
        ),
      );
    }

    return const TrainerScene(child: SizedBox.shrink());
  }
}
