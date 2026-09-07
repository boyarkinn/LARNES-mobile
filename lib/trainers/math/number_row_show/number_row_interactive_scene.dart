import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_colors.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_audio.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_geometry.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_model.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_sizes.dart';

enum NumberRowScenePhase { show, scatter, assemble }

/// Web: `platform/src/trainers/math/number-row-show/number-row-interactive-scene.tsx`
class NumberRowInteractiveScene extends StatefulWidget {
  const NumberRowInteractiveScene({
    super.key,
    required this.studyDigit,
    required this.stepPauseSec,
    this.disabled = false,
    required this.onComplete,
  });

  final int studyDigit;
  final double stepPauseSec;
  final bool disabled;
  final VoidCallback onComplete;

  @override
  State<NumberRowInteractiveScene> createState() => _NumberRowInteractiveSceneState();
}

class _NumberRowInteractiveSceneState extends State<NumberRowInteractiveScene>
    with SingleTickerProviderStateMixin {
  static const _slotSize = 56.0;
  static const _chipFontSize = 40.0;
  static const _scatterTransitionMs = 650;
  static const _assembleDigitColor = Color(0xFF475569);

  var _phase = NumberRowScenePhase.show;
  var _visibleCount = 0;
  var _isScatterSettled = false;
  final _placedDigits = <int>{};
  var _hasErrorFlash = false;
  var _isComplete = false;

  Timer? _showTimer;
  Timer? _scatterTimer;
  Timer? _errorFlashTimer;
  Object _runToken = Object();
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
    _restartScene();
  }

  @override
  void didUpdateWidget(NumberRowInteractiveScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studyDigit != widget.studyDigit ||
        oldWidget.stepPauseSec != widget.stepPauseSec) {
      _restartScene();
    }
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _scatterTimer?.cancel();
    _errorFlashTimer?.cancel();
    _shakeController.dispose();
    unawaited(cancelNumberRowShowAudio());
    super.dispose();
  }

  void _restartScene() {
    final runToken = Object();
    _runToken = runToken;
    _showTimer?.cancel();
    _scatterTimer?.cancel();
    _errorFlashTimer?.cancel();
    unawaited(cancelNumberRowShowAudio());

    setState(() {
      _phase = NumberRowScenePhase.show;
      _visibleCount = 0;
      _isScatterSettled = false;
      _placedDigits.clear();
      _hasErrorFlash = false;
      _isComplete = false;
    });

    unawaited(_runShowPhase(runToken));
  }

  Future<void> _runShowPhase(Object runToken) async {
    final studyDigit = normalizeStudyDigit(widget.studyDigit);
    final pauseSec = normalizeStepPauseSec(widget.stepPauseSec);
    final rowDigits = getRowDigits(studyDigit);

    for (var index = 0; index < rowDigits.length; index++) {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      final digit = rowDigits[index];
      setState(() => _visibleCount = index + 1);

      try {
        await playNumberRowDigitAudio(digit);
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (index < rowDigits.length - 1) {
        await Future<void>.delayed(
          Duration(milliseconds: (pauseSec * 1000).round()),
        );
      }
    }

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    setState(() => _phase = NumberRowScenePhase.scatter);

    _scatterTimer?.cancel();
    _scatterTimer = Timer(const Duration(milliseconds: _scatterTransitionMs), () {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }
      setState(() {
        _isScatterSettled = true;
        _phase = NumberRowScenePhase.assemble;
      });
    });
  }

  bool get _isLocked =>
      widget.disabled || _isComplete || _phase != NumberRowScenePhase.assemble || !_isScatterSettled;

  void _flashError() {
    _errorFlashTimer?.cancel();
    setState(() => _hasErrorFlash = true);
    _shakeController.forward(from: 0);
    _errorFlashTimer = Timer(const Duration(milliseconds: 550), () {
      if (mounted) {
        setState(() => _hasErrorFlash = false);
      }
    });
  }

  void _tryPlaceDigit(int digit) {
    if (_isLocked || _placedDigits.contains(digit)) {
      return;
    }

    setState(() {
      _placedDigits.add(digit);
      _hasErrorFlash = false;
    });

    if (isRowComplete(_placedDigits, widget.studyDigit) && !_isComplete) {
      setState(() => _isComplete = true);
      widget.onComplete();
    }
  }

  Color _digitColor(int digit, {required bool highlightStudy, required bool uniformColor}) {
    if (uniformColor) {
      return _assembleDigitColor;
    }
    if (highlightStudy && isStudyDigit(digit, widget.studyDigit)) {
      return getDigitDisplayColor(digit);
    }
    return numberRowInactiveColor;
  }

  Widget _digitLabel(
    int digit, {
    required bool highlightStudy,
    required bool uniformColor,
  }) {
    return Text(
      '$digit',
      style: TextStyle(
        fontSize: _chipFontSize,
        fontWeight: FontWeight.w800,
        color: _digitColor(
          digit,
          highlightStudy: highlightStudy,
          uniformColor: uniformColor,
        ),
        height: 1,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _chip({
    required int digit,
    required bool highlightStudy,
    required bool uniformColor,
    Color? backgroundColor,
  }) {
    return Container(
      width: _slotSize,
      height: _slotSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _digitLabel(
        digit,
        highlightStudy: highlightStudy,
        uniformColor: uniformColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studyDigit = normalizeStudyDigit(widget.studyDigit);
    final rowDigits = getRowDigits(studyDigit);
    final scatterPositions = buildScatterPositions(
      rowDigits.length,
      buildScatterSeed(studyDigit, normalizeStepPauseSec(widget.stepPauseSec)),
    );

    final registerBorderColor = _hasErrorFlash
        ? const Color(0xCCFB7185)
        : const Color(0xB3CBD5E1);
    final registerBackground = _hasErrorFlash
        ? const Color(0x59FFE4E6)
        : Colors.transparent;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: _phase == NumberRowScenePhase.show
                ? Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var index = 0; index < getNumberRowSlots(studyDigit).length; index++)
                          if (index < _visibleCount)
                            TweenAnimationBuilder<double>(
                              key: ValueKey('show-${rowDigits[index]}'),
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.scale(
                                    scale: 0.88 + 0.12 * value,
                                    child: child,
                                  ),
                                );
                              },
                              child: _chip(
                                digit: rowDigits[index],
                                highlightStudy: true,
                                uniformColor: false,
                                backgroundColor: Colors.white.withValues(alpha: 0.7),
                              ),
                            )
                          else
                            SizedBox(
                              width: _slotSize,
                              height: _slotSize,
                            ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      AnimatedBuilder(
                        animation: _shakeController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeOffset.value, 0),
                            child: child,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: registerBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: registerBorderColor, width: 2),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final slot in getNumberRowSlots(studyDigit))
                                _SlotTarget(
                                  digit: slot.digit,
                                  disabled: _isLocked,
                                  placed: _placedDigits.contains(slot.digit),
                                  onAccepted: _tryPlaceDigit,
                                  onRejected: _flashError,
                                  child: Container(
                                    width: _slotSize,
                                    height: _slotSize,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _placedDigits.contains(slot.digit)
                                          ? const Color(0x80ECFDF5)
                                          : Colors.white.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _placedDigits.contains(slot.digit)
                                            ? const Color(0xCC4ADE80)
                                            : const Color(0xCCCBD5E1),
                                        width: 2,
                                      ),
                                    ),
                                    child: _placedDigits.contains(slot.digit)
                                        ? _digitLabel(
                                            slot.digit,
                                            highlightStudy: false,
                                            uniformColor: true,
                                          )
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (var index = 0; index < rowDigits.length; index++)
                                  if (!_placedDigits.contains(rowDigits[index]))
                                    _ScatterChip(
                                      digit: rowDigits[index],
                                      disabled: _isLocked,
                                      scatter: scatterPositions[index],
                                      showAtRow: _phase == NumberRowScenePhase.scatter && !_isScatterSettled,
                                      areaWidth: constraints.maxWidth,
                                      areaHeight: constraints.maxHeight,
                                      onAcceptedSlot: _tryPlaceDigit,
                                      onRejected: _flashError,
                                      child: _chip(
                                        digit: rowDigits[index],
                                        highlightStudy: false,
                                        uniformColor: true,
                                      ),
                                    ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _SlotTarget extends StatelessWidget {
  const _SlotTarget({
    required this.digit,
    required this.disabled,
    required this.placed,
    required this.onAccepted,
    required this.onRejected,
    required this.child,
  });

  final int digit;
  final bool disabled;
  final bool placed;
  final ValueChanged<int> onAccepted;
  final VoidCallback onRejected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (placed || disabled) {
      return child;
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        if (details.data == digit) {
          return true;
        }
        onRejected();
        return false;
      },
      onAcceptWithDetails: (details) => onAccepted(details.data),
      builder: (context, candidate, rejected) {
        final highlighted = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: highlighted
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x334F46E5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                )
              : null,
          child: child,
        );
      },
    );
  }
}

class _ScatterChip extends StatelessWidget {
  const _ScatterChip({
    required this.digit,
    required this.disabled,
    required this.scatter,
    required this.showAtRow,
    required this.areaWidth,
    required this.areaHeight,
    required this.onAcceptedSlot,
    required this.onRejected,
    required this.child,
  });

  final int digit;
  final bool disabled;
  final ScatterPosition scatter;
  final bool showAtRow;
  final double areaWidth;
  final double areaHeight;
  final ValueChanged<int> onAcceptedSlot;
  final VoidCallback onRejected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final left = areaWidth * scatter.xPercent / 100 - 28;
    final top = showAtRow
        ? areaHeight * 0.18 - 28
        : areaHeight * scatter.yPercent / 100 - 28;

    final positioned = AnimatedPositioned(
      duration: Duration(milliseconds: showAtRow ? _NumberRowInteractiveSceneState._scatterTransitionMs : 0),
      curve: Curves.easeOutBack,
      left: left,
      top: top,
      child: child,
    );

    if (disabled) {
      return positioned;
    }

    return AnimatedPositioned(
      duration: Duration(milliseconds: showAtRow ? _NumberRowInteractiveSceneState._scatterTransitionMs : 0),
      curve: Curves.easeOutBack,
      left: left,
      top: top,
      child: Draggable<int>(
        data: digit,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(opacity: 0.92, child: child),
        ),
        childWhenDragging: Opacity(opacity: 0.25, child: child),
        onDragEnd: (_) {},
        child: child,
      ),
    );
  }
}
