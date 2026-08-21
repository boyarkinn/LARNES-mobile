import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/definition.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/model.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/wedge_tables_audio.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/wedge_tables_scene.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/wedge_tables_sizes.dart';
import 'package:larnes_mobile/trainers/shared/param_coerce.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

enum WedgePhase { instruction, play }

/// Web: `platform/src/trainers/reading/wedge-tables/component.tsx`
class WedgeTablesTrainer extends StatefulWidget {
  const WedgeTablesTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<WedgeTablesTrainer> createState() => _WedgeTablesTrainerState();
}

class _WedgeTablesTrainerState extends State<WedgeTablesTrainer> {
  late List<List<WedgeRow>> _rounds;
  late int _displayMs;
  late String _orientation;
  late int _rowCount;

  var _phase = WedgePhase.instruction;
  var _roundIndex = 0;
  var _rowIndex = 0;
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
  void didUpdateWidget(WedgeTablesTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_semanticParamsChanged(oldWidget.params, widget.params)) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelWedgeTablesAudio());
    super.dispose();
  }

  bool _semanticParamsChanged(
    Map<String, dynamic> previous,
    Map<String, dynamic> next,
  ) {
    return previous['category'] != next['category'] ||
        previous['displaySeconds'] != next['displaySeconds'] ||
        previous['orientation'] != next['orientation'] ||
        previous['rounds'] != next['rounds'] ||
        previous['rowCount'] != next['rowCount'];
  }

  int _readIntParam(String key, int fallback) {
    return coerceInt(widget.params[key]) ?? fallback;
  }

  double _readDoubleParam(String key, double fallback) {
    return coerceDouble(widget.params[key]) ?? fallback;
  }

  String _readStringParam(String key, String fallback) {
    final value = widget.params[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return fallback;
  }

  void _startSession() {
    final runToken = Object();
    _runToken = runToken;
    _slideTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelWedgeTablesAudio());

    final category = _readStringParam('category', kWedgeCategoryDefault);
    final rounds = _readIntParam('rounds', kWedgeRoundsDefault);
    _rowCount = _readIntParam('rowCount', kWedgeRowCountDefault);
    _orientation = _readStringParam('orientation', kWedgeOrientationDefault);
    final displaySeconds = _readDoubleParam(
      'displaySeconds',
      kWedgeDisplaySecondsDefault,
    );

    setState(() {
      _rounds = List<List<WedgeRow>>.generate(
        rounds,
        (_) => generateWedgeRows(
          GenerateWedgeRowsInput(category: category, rowCount: _rowCount),
        ),
      );
      _displayMs = (displaySeconds * 1000).round();
      _phase = WedgePhase.instruction;
      _roundIndex = 0;
      _rowIndex = 0;
      _isFinished = false;
      _completeCalled = false;
    });

    unawaited(_runInstruction(runToken));
  }

  Future<void> _runInstruction(Object runToken) async {
    await playWedgeTablesInstruction();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    setState(() {
      _phase = WedgePhase.play;
    });
    _scheduleSlide();
  }

  void _scheduleSlide() {
    _slideTimer?.cancel();

    if (_phase != WedgePhase.play || _isFinished) {
      return;
    }

    final currentRound = _rounds.isEmpty ? const <WedgeRow>[] : _rounds[_roundIndex];
    if (currentRound.isEmpty) {
      setState(() => _isFinished = true);
      _scheduleComplete();
      return;
    }

    _slideTimer = Timer(Duration(milliseconds: _displayMs), () {
      if (!mounted) {
        return;
      }

      if (_rowIndex < currentRound.length - 1) {
        setState(() => _rowIndex++);
        _scheduleSlide();
        return;
      }

      if (_roundIndex < _rounds.length - 1) {
        setState(() {
          _roundIndex++;
          _rowIndex = 0;
        });
        _scheduleSlide();
        return;
      }

      setState(() => _isFinished = true);
      _scheduleComplete();
    });
  }

  void _scheduleComplete() {
    if (_completeCalled || widget.onComplete == null) {
      return;
    }

    _completeCalled = true;
    _slideTimer?.cancel();
    _completeTimer = Timer(
      const Duration(milliseconds: kWedgeFinishDelayMs),
      () {
        if (mounted) {
          widget.onComplete?.call();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _rounds.isEmpty || _rounds[_roundIndex].isEmpty
        ? null
        : _rounds[_roundIndex][_rowIndex];

    return TrainerScene(
      child: _phase == WedgePhase.play && current != null
          ? WedgeTablesScene(
              left: current.left,
              orientation: _orientation,
              right: current.right,
              rowCount: _rowCount,
              rowIndex: _rowIndex,
              rowKey: '$_roundIndex-$_rowIndex-${current.left}-${current.right}',
            )
          : const SizedBox.expand(),
    );
  }
}
