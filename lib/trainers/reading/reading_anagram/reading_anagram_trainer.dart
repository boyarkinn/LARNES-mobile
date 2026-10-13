import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_instruction.dart';
import 'package:larnes_mobile/trainers/reading/reading_anagram/model.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/first_words/resolve_first_word.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingAnagramTrainer extends StatefulWidget {
  const ReadingAnagramTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ReadingAnagramTrainer> createState() => _ReadingAnagramTrainerState();
}

class _ReadingAnagramTrainerState extends State<ReadingAnagramTrainer> {
  Timer? _instructionTimer;
  Timer? _typeTimer;
  var _phase = 'instruction';
  var _instructionLength = 0;
  var _instructionSpeech = '';
  void Function()? _cancelInstruction;
  var _placed = 0;
  late String _hint;
  late String _hintText;
  late String _slug;
  late List<String> _letters;
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
  void didUpdateWidget(ReadingAnagramTrainer oldWidget) {
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
    final payload = readTrainerRuntimeSnapshot('reading-anagram', widget.params);
    final letters = payload?['letters'];
    final order = payload?['order'];
    if (letters is List && letters.length >= 2 && order is List && order.isNotEmpty) {
      _letters = letters.map((item) => item.toString()).toList();
      _order = order.map((item) => item is num ? item.toInt() : 0).toList();
      _hint = readingAnagramHint(payload?['hint']);
      _hintText = payload?['hintText']?.toString() ?? '';
      _slug = payload?['slug']?.toString() ?? readingAnagramDefaultSlug;
    } else {
      final card = readingAnagramCardBySlug(widget.params['anagramSlug']?.toString() ?? readingAnagramDefaultSlug) ??
          readingAnagramCardBySlug(readingAnagramDefaultSlug);
      _hint = readingAnagramHint(widget.params['anagramHint']);
      _letters = card?.label.split('') ?? const <String>[];
      _order = readingAnagramOrder(_letters.length);
      _hintText = _hint == 'definition'
          ? (card?.definition ?? '')
          : _hint == 'sentence'
              ? (card?.sentence ?? '')
              : '';
      _slug = card?.slug ?? readingAnagramDefaultSlug;
    }
    _resetToken = '$_slug|$_hint|${_letters.join()}|${_order.join(',')}';
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
      fallbackMs: readingAnagramInstructionMs,
      fallbackText: readingAnagramInstructionText,
      isMounted: () => mounted,
      onFinished: () {
      if (!mounted) return;
      setState(() => _phase = 'play');
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
      trainerKey: 'reading-anagram',
    );
  }

  void _choose(int index) {
    if (index != _placed) return;
    final next = _placed + 1;
    setState(() => _placed = next);
    if (next == _letters.length) widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'instruction') {
      return TrainerInstructionScene(length: _instructionLength, text: _instructionSpeech.isEmpty ? readingAnagramInstructionText : _instructionSpeech);
    }

    final image = _hint == 'picture' ? getFirstWordImageWidgetAsset(_slug) : null;
    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null)
              Image.asset(image, height: 140, fit: BoxFit.contain, semanticLabel: ''),
            if (_hint != 'picture')
              Text(
                _hintText,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Color(0xFF20352D), fontSize: 24, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 16),
            Text(
              _letters.take(_placed).join(),
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Color(0xFFDB2777), fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: 8),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final index in _order)
                  if (index >= _placed)
                    FilledButton(
                      onPressed: () => _choose(index),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE7EEF2),
                        foregroundColor: const Color(0xFF20352D),
                        minimumSize: const Size(56, 56),
                      ),
                      child: Text(_letters[index], style: const TextStyle(fontSize: 24)),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
