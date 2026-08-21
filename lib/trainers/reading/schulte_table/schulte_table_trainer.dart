import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/schulte_table/definition.dart';
import 'package:larnes_mobile/trainers/reading/schulte_table/model.dart';
import 'package:larnes_mobile/trainers/reading/schulte_table/schulte_table_audio.dart';
import 'package:larnes_mobile/trainers/reading/schulte_table/schulte_table_scene.dart';
import 'package:larnes_mobile/trainers/reading/schulte_table/schulte_table_sizes.dart';
import 'package:larnes_mobile/trainers/shared/param_coerce.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

enum SchultePhase { instruction, play }

/// Web: `platform/src/trainers/reading/schulte-table/component.tsx`
class SchulteTableTrainer extends StatefulWidget {
  const SchulteTableTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<SchulteTableTrainer> createState() => _SchulteTableTrainerState();
}

class _SchulteTableTrainerState extends State<SchulteTableTrainer> {
  late SchulteTable _table;
  late int _rounds;
  late String _category;
  late String _order;

  var _phase = SchultePhase.instruction;
  var _roundIndex = 0;
  var _foundValues = <String>{};
  String? _wrongCellId;
  var _isSettling = false;
  var _completeCalled = false;
  Object _runToken = Object();

  Timer? _wrongTimer;
  Timer? _settleTimer;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void didUpdateWidget(SchulteTableTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_semanticParamsChanged(oldWidget.params, widget.params)) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _wrongTimer?.cancel();
    _settleTimer?.cancel();
    unawaited(cancelSchulteTableAudio());
    super.dispose();
  }

  bool _semanticParamsChanged(
    Map<String, dynamic> previous,
    Map<String, dynamic> next,
  ) {
    return previous['category'] != next['category'] ||
        previous['gridSize'] != next['gridSize'] ||
        previous['order'] != next['order'] ||
        previous['rounds'] != next['rounds'];
  }

  int _readIntParam(String key, int fallback) {
    return coerceInt(widget.params[key]) ?? fallback;
  }

  String _readStringParam(String key, String fallback) {
    final value = widget.params[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return fallback;
  }

  bool _readBoolParam(String key) {
    return coerceBool(widget.params[key]) ?? false;
  }

  void _startSession() {
    final runToken = Object();
    _runToken = runToken;
    _wrongTimer?.cancel();
    _settleTimer?.cancel();
    unawaited(cancelSchulteTableAudio());

    _rounds = _readIntParam('rounds', kSchulteRoundsDefault);
    _category = _readStringParam('category', kSchulteCategoryDefault);
    _order = _readStringParam('order', kSchulteOrderDefault);

    setState(() {
      _table = _generateTable();
      _phase = SchultePhase.instruction;
      _roundIndex = 0;
      _foundValues = {};
      _wrongCellId = null;
      _isSettling = false;
      _completeCalled = false;
    });

    unawaited(_runInstruction(runToken));
  }

  SchulteTable _generateTable() {
    return generateSchulteTable(
      GenerateSchulteTableInput(
        category: _category,
        gridSize: _readIntParam('gridSize', kSchulteGridSizeDefault),
        order: _order,
      ),
    );
  }

  Future<void> _runInstruction(Object runToken) async {
    await playSchulteTableInstruction();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    setState(() {
      _phase = SchultePhase.play;
    });
  }

  void _markWrong(String cellId) {
    _wrongTimer?.cancel();
    setState(() => _wrongCellId = cellId);
    _wrongTimer = Timer(const Duration(milliseconds: kSchulteWrongShakeMs), () {
      if (mounted) {
        setState(() => _wrongCellId = null);
      }
    });
  }

  void _handleCellTap(SchulteCell cell) {
    if (_phase != SchultePhase.play ||
        _isSettling ||
        _foundValues.contains(cell.value)) {
      return;
    }

    if (!isNextSchulteTarget(cell.value, _table.sequence, _foundValues.length)) {
      _markWrong(schulteCellId(cell));
      return;
    }

    final nextFound = {..._foundValues, cell.value};
    setState(() => _foundValues = nextFound);

    if (nextFound.length < _table.sequence.length) {
      return;
    }

    setState(() => _isSettling = true);
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: kSchulteRoundSettleMs), () {
      if (!mounted) {
        return;
      }

      if (_roundIndex + 1 < _rounds) {
        setState(() {
          _roundIndex += 1;
          _table = _generateTable();
          _foundValues = {};
          _wrongCellId = null;
          _isSettling = false;
        });
        return;
      }

      if (_completeCalled) {
        return;
      }

      _completeCalled = true;
      widget.onComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: _phase == SchultePhase.play
          ? SchulteTableScene(
              disabled: _isSettling,
              foundValues: _foundValues,
              onCellTap: _handleCellTap,
              showCenterDot: _readBoolParam('centerDot'),
              showFound: _readBoolParam('showFound'),
              symbolOrientation: _readStringParam(
                'symbolOrientation',
                kSchulteOrientationDefault,
              ),
              table: _table,
              wrongCellId: _wrongCellId,
            )
          : const SizedBox.expand(),
    );
  }
}
