import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/stroop_colors/definition.dart';
import 'package:larnes_mobile/trainers/reading/stroop_colors/model.dart';
import 'package:larnes_mobile/trainers/reading/stroop_colors/stroop_colors_audio.dart';
import 'package:larnes_mobile/trainers/reading/stroop_colors/stroop_colors_scene.dart';
import 'package:larnes_mobile/trainers/reading/stroop_colors/stroop_colors_sizes.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

enum StroopPhase { instruction, play }

/// Web: `platform/src/trainers/reading/stroop-colors/component.tsx`
class StroopColorsTrainer extends StatefulWidget {
  const StroopColorsTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<StroopColorsTrainer> createState() => _StroopColorsTrainerState();
}

class _StroopColorsTrainerState extends State<StroopColorsTrainer> {
  late List<StroopColorItem> _items;
  late int _displayMs;

  var _phase = StroopPhase.instruction;
  var _index = 0;
  var _isFinished = false;
  var _completeCalled = false;
  Object _runToken = Object();

  Timer? _slideTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void didUpdateWidget(StroopColorsTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params['wordCount'] != widget.params['wordCount'] ||
        oldWidget.params['displaySeconds'] != widget.params['displaySeconds']) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelStroopColorsAudio());
    super.dispose();
  }

  int _readIntParam(String key, int fallback) {
    final value = widget.params[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? fallback;
  }

  double _readDoubleParam(String key, double fallback) {
    final value = widget.params[key];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? fallback;
  }

  void _startSession() {
    final runToken = Object();
    _runToken = runToken;
    _slideTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelStroopColorsAudio());

    final wordCount = _readIntParam('wordCount', kStroopWordCountDefault);
    final displaySeconds = _readDoubleParam(
      'displaySeconds',
      kStroopDisplaySecondsDefault,
    );

    setState(() {
      _items = generateStroopItems(GenerateStroopItemsInput(wordCount: wordCount));
      _displayMs = (displaySeconds * 1000).round();
      _phase = StroopPhase.instruction;
      _index = 0;
      _isFinished = false;
      _completeCalled = false;
    });

    unawaited(_runInstruction(runToken));
  }

  Future<void> _runInstruction(Object runToken) async {
    await playStroopColorsInstruction();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    setState(() {
      _phase = StroopPhase.play;
    });
    _scheduleSlide();
  }

  void _scheduleSlide() {
    _slideTimer?.cancel();

    if (_phase != StroopPhase.play || _isFinished || _items.isEmpty) {
      return;
    }

    _slideTimer = Timer(Duration(milliseconds: _displayMs), () {
      if (!mounted) {
        return;
      }

      if (_index >= _items.length - 1) {
        setState(() => _isFinished = true);
        _scheduleComplete();
        return;
      }

      setState(() => _index++);
      _scheduleSlide();
    });
  }

  void _scheduleComplete() {
    if (_completeCalled || widget.onComplete == null) {
      return;
    }

    _completeCalled = true;
    _slideTimer?.cancel();
    _completeTimer = Timer(
      const Duration(milliseconds: stroopFinishDelayMs),
      () {
        if (mounted) {
          widget.onComplete?.call();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _items.isEmpty ? null : _items[_index];

    return TrainerScene(
      child: _phase == StroopPhase.play && current != null
          ? StroopColorsScene(
              inkHex: stroopColors[current.ink]!.hex,
              word: stroopColors[current.word]!.label,
              wordKey: '${current.word}-${current.ink}-$_index',
            )
          : const SizedBox.expand(),
    );
  }
}
