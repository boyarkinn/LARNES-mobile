import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/generate.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_table/parse_step.dart';
import 'package:larnes_mobile/trainers/shared/param_coerce.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Web: `platform/src/trainers/mental-arithmetic/topic-chain-table/component.tsx`
class TopicChainTableTrainer extends StatefulWidget {
  const TopicChainTableTrainer({
    super.key,
    required this.params,
  });

  final Map<String, dynamic> params;

  @override
  State<TopicChainTableTrainer> createState() => _TopicChainTableTrainerState();
}

class _ColumnState {
  _ColumnState({required this.id, required this.steps});

  final String id;
  List<ChainStep> steps;
}

class _TopicChainTableTrainerState extends State<TopicChainTableTrainer> {
  static const _cellWidth = 92.0;
  static const _cellHeight = 52.0;
  static const _edge = 3.0;
  static const _generateRetries = 8;
  static const _borderColor = Color(0xFF166534);

  static const _rainbowTones = <Color>[
    Color(0xFFFEE2E2), // red-100
    Color(0xFFFFEDD5), // orange-100
    Color(0xFFFEF3C7), // amber-100
    Color(0xFFFEF9C3), // yellow-100
    Color(0xFFECFCCB), // lime-100
    Color(0xFFDCFCE7), // green-100
    Color(0xFFD1FAE5), // emerald-100
    Color(0xFFCFFAFE), // cyan-100
    Color(0xFFE0F2FE), // sky-100
    Color(0xFFDBEAFE), // blue-100
    Color(0xFFE0E7FF), // indigo-100
    Color(0xFFEDE9FE), // violet-100
  ];

  List<_ColumnState> _columns = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _regenerateAll();
  }

  @override
  void didUpdateWidget(TopicChainTableTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_semanticParamsChanged(oldWidget.params, widget.params)) {
      _regenerateAll();
    }
  }

  bool _semanticParamsChanged(Map<String, dynamic> a, Map<String, dynamic> b) {
    return a['topicId'] != b['topicId'] ||
        a['actionCount'] != b['actionCount'] ||
        a['exampleCount'] != b['exampleCount'];
  }

  int get _actionCount => coerceInt(widget.params['actionCount']) ?? 4;

  int get _exampleCount =>
      (coerceInt(widget.params['exampleCount']) ?? 5).clamp(1, 12);

  String get _topicId => widget.params['topicId'] as String? ?? 'simple-1';

  Color _columnTone(int columnIndex) {
    if (columnIndex.isOdd) {
      return Colors.white;
    }
    return _rainbowTones[(columnIndex ~/ 2) % _rainbowTones.length];
  }

  List<ChainStep>? _tryGenerateSteps() {
    for (var attempt = 0; attempt < _generateRetries; attempt += 1) {
      try {
        return generateChain(
          GenerateConfig(
            topicId: _topicId,
            actionCount: _actionCount,
            signMode: 'mix',
          ),
        ).steps;
      } on GenerateNotImplementedError {
        rethrow;
      } on GenerateFailedError {
        // retry
      }
    }
    return null;
  }

  void _regenerateAll() {
    final columns = <_ColumnState>[];
    String? error;

    try {
      for (var index = 0; index < _exampleCount; index += 1) {
        final steps = _tryGenerateSteps();
        if (steps == null) {
          error =
              'Не удалось сгенерировать пример. Смените тему или число действий.';
          break;
        }
        columns.add(
          _ColumnState(
            id: 'col-$index-${DateTime.now().microsecondsSinceEpoch}-$index',
            steps: steps,
          ),
        );
      }
    } catch (caught) {
      error = caught.toString();
    }

    setState(() {
      _columns = columns;
      _error = error;
    });
  }

  void _regenerateColumn(int columnIndex) {
    try {
      final steps = _tryGenerateSteps();
      if (steps == null) {
        setState(() {
          _error = 'Не удалось перегенерировать колонку.';
        });
        return;
      }

      setState(() {
        _error = null;
        _columns = [
          for (var index = 0; index < _columns.length; index += 1)
            if (index == columnIndex)
              _ColumnState(
                id:
                    'col-$columnIndex-${DateTime.now().microsecondsSinceEpoch}',
                steps: steps,
              )
            else
              _columns[index],
        ];
      });
    } catch (caught) {
      setState(() {
        _error = caught.toString();
      });
    }
  }

  void _updateStep(int columnIndex, int stepIndex, ChainStep next) {
    setState(() {
      final column = _columns[columnIndex];
      column.steps = [
        for (var row = 0; row < column.steps.length; row += 1)
          if (row == stepIndex) next else column.steps[row],
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final tableWidth = _columns.length * _cellWidth;

    return TrainerScene(
      child: ColoredBox(
        color: Colors.white,
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFBE123C),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (_columns.isNotEmpty) ...[
                    SizedBox(
                      width: tableWidth,
                      child: Row(
                        children: [
                          for (var columnIndex = 0;
                              columnIndex < _columns.length;
                              columnIndex += 1)
                            SizedBox(
                              width: _cellWidth,
                              height: 36,
                              child: IconButton(
                                tooltip:
                                    'Перегенерировать пример ${columnIndex + 1}',
                                onPressed: () =>
                                    _regenerateColumn(columnIndex),
                                icon: const Icon(
                                  Icons.refresh,
                                  size: 18,
                                  color: Color(0xFF737373),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: tableWidth + _edge * 2,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _borderColor,
                          width: _edge,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var stepIndex = 0;
                              stepIndex < _actionCount;
                              stepIndex += 1)
                            Row(
                              children: [
                                for (var columnIndex = 0;
                                    columnIndex < _columns.length;
                                    columnIndex += 1)
                                  _StepCell(
                                    width: _cellWidth,
                                    height: _cellHeight,
                                    color: _columnTone(columnIndex),
                                    showRightBorder:
                                        columnIndex < _columns.length - 1,
                                    showBottomBorder: true,
                                    edge: _edge,
                                    step: _columns[columnIndex]
                                        .steps[stepIndex],
                                    onChanged: (next) => _updateStep(
                                      columnIndex,
                                      stepIndex,
                                      next,
                                    ),
                                  ),
                              ],
                            ),
                          Row(
                            children: [
                              for (var columnIndex = 0;
                                  columnIndex < _columns.length;
                                  columnIndex += 1)
                                Container(
                                  width: _cellWidth,
                                  height: _cellHeight,
                                  decoration: BoxDecoration(
                                    color: _columnTone(columnIndex),
                                    border: Border(
                                      top: const BorderSide(
                                        color: _borderColor,
                                        width: _edge,
                                      ),
                                      right: columnIndex < _columns.length - 1
                                          ? const BorderSide(
                                              color: Colors.black87,
                                              width: _edge,
                                            )
                                          : BorderSide.none,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCell extends StatelessWidget {
  const _StepCell({
    required this.width,
    required this.height,
    required this.color,
    required this.showRightBorder,
    required this.showBottomBorder,
    required this.edge,
    required this.step,
    required this.onChanged,
  });

  final double width;
  final double height;
  final Color color;
  final bool showRightBorder;
  final bool showBottomBorder;
  final double edge;
  final ChainStep step;
  final ValueChanged<ChainStep> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        border: Border(
          bottom: showBottomBorder
              ? const BorderSide(color: Color(0xFFD4D4D4))
              : BorderSide.none,
          right: showRightBorder
              ? BorderSide(color: Colors.black87, width: edge)
              : BorderSide.none,
        ),
      ),
      child: _EditableStep(
        step: step,
        onChanged: onChanged,
      ),
    );
  }
}

class _EditableStep extends StatefulWidget {
  const _EditableStep({
    required this.step,
    required this.onChanged,
  });

  final ChainStep step;
  final ValueChanged<ChainStep> onChanged;

  @override
  State<_EditableStep> createState() => _EditableStepState();
}

class _EditableStepState extends State<_EditableStep> {
  var _editing = false;
  late final TextEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: formatChainStep(widget.step));
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) {
        _commit();
      }
    });
  }

  @override
  void didUpdateWidget(_EditableStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.step != widget.step) {
      _controller.text = formatChainStep(widget.step);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    final parsed = parseEditableStep(_controller.text);
    if (parsed != null) {
      widget.onChanged(parsed);
      _controller.text = formatChainStep(parsed);
    } else {
      _controller.text = formatChainStep(widget.step);
    }
    setState(() {
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return TextField(
        controller: _controller,
        focusNode: _focus,
        autofocus: true,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4),
        ),
        onSubmitted: (_) => _commit(),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _editing = true;
            _controller.text = formatChainStep(widget.step);
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _focus.requestFocus();
          });
        },
        child: Center(
          child: Text(
            formatChainStep(widget.step),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
