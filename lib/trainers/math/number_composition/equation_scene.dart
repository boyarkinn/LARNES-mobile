import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_colors.dart';
import 'package:larnes_mobile/trainers/math/number_composition/composition_dot_group.dart';
import 'package:larnes_mobile/trainers/math/number_composition/composition_reveal.dart';
import 'package:larnes_mobile/trainers/math/number_composition/composition_scene_layout.dart';
import 'package:larnes_mobile/trainers/math/number_composition/composition_sizes.dart';
import 'package:larnes_mobile/trainers/math/number_composition/missing_slot.dart';
import 'package:larnes_mobile/trainers/math/number_composition/number_composition_model.dart';

/// Web v2: `platform/src/trainers/math/number-composition/equation-scene.tsx`
class EquationScene extends StatelessWidget {
  const EquationScene({
    super.key,
    required this.equation,
    required this.mode,
    this.isSlotShaking = false,
    this.selectedValue,
    this.acceptSlotDrops = false,
    this.onSlotAccept,
    this.slotKey,
  });

  final CompositionEquation equation;
  final CompositionPhase mode;
  final bool isSlotShaking;
  final int? selectedValue;
  final bool acceptSlotDrops;
  final ValueChanged<int>? onSlotAccept;
  final GlobalKey<MissingSlotState>? slotKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final viewportHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final showDigits = mode == 'demo-digits' || mode == 'practice-digits';
        final isPractice = isPracticePhase(mode);
        final layout = computeCompositionSceneLayout(
          viewportWidth: viewportWidth,
          viewportHeight: viewportHeight,
          showDigits: showDigits,
          isPractice: isPractice,
        );
        final dotSlotSize = layout.dotSlotSize;
        final digitSize = layout.digitSize;
        final operatorSize = layout.operatorSize;

        if (isPractice) {
          return _PracticeEquation(
            acceptSlotDrops: acceptSlotDrops,
            digitSize: digitSize,
            dotSlotSize: dotSlotSize,
            equation: equation,
            isSlotShaking: isSlotShaking,
            onSlotAccept: onSlotAccept,
            operatorSize: operatorSize,
            selectedValue: selectedValue,
            showDigits: showDigits,
            slotKey: slotKey,
          );
        }

        return _DemoEquation(
          digitSize: digitSize,
          dotSlotSize: dotSlotSize,
          equation: equation,
          operatorSize: operatorSize,
          showDigits: showDigits,
        );
      },
    );
  }
}

class _DemoEquation extends StatelessWidget {
  const _DemoEquation({
    required this.equation,
    required this.showDigits,
    required this.dotSlotSize,
    required this.digitSize,
    required this.operatorSize,
  });

  final CompositionEquation equation;
  final bool showDigits;
  final double dotSlotSize;
  final double digitSize;
  final double operatorSize;

  @override
  Widget build(BuildContext context) {
    return _EquationRow(
      children: [
        _EquationBeat(
          beatIndex: 0,
          child: showDigits
              ? _DigitValue(
                  color: getDigitDisplayColor(equation.knownPart),
                  fontSize: digitSize,
                  value: equation.knownPart,
                )
              : CompositionDotGroup(
                  count: equation.knownPart,
                  frameSize: dotSlotSize,
                ),
        ),
        _EquationBeat(
          beatIndex: 1,
          child: _OperatorSign(fontSize: operatorSize, text: '+'),
        ),
        _EquationBeat(
          beatIndex: 2,
          child: showDigits
              ? _DigitValue(
                  color: getDigitDisplayColor(equation.missingPart),
                  fontSize: digitSize,
                  value: equation.missingPart,
                )
              : CompositionDotGroup(
                  count: equation.missingPart,
                  frameSize: dotSlotSize,
                ),
        ),
        _EquationBeat(
          beatIndex: 3,
          child: _OperatorSign(fontSize: operatorSize, text: '='),
        ),
        _EquationBeat(
          beatIndex: 4,
          child: showDigits
              ? _DigitValue(
                  color: compositionWholeColor,
                  fontSize: digitSize,
                  value: equation.whole,
                )
              : CompositionDotGroup(
                  count: equation.whole,
                  dotColor: compositionWholeColor,
                  frameSize: dotSlotSize,
                ),
        ),
      ],
    );
  }
}

class _PracticeEquation extends StatelessWidget {
  const _PracticeEquation({
    required this.equation,
    required this.showDigits,
    required this.dotSlotSize,
    required this.digitSize,
    required this.operatorSize,
    required this.isSlotShaking,
    required this.selectedValue,
    required this.acceptSlotDrops,
    required this.onSlotAccept,
    required this.slotKey,
  });

  final CompositionEquation equation;
  final bool showDigits;
  final double dotSlotSize;
  final double digitSize;
  final double operatorSize;
  final bool isSlotShaking;
  final int? selectedValue;
  final bool acceptSlotDrops;
  final ValueChanged<int>? onSlotAccept;
  final GlobalKey<MissingSlotState>? slotKey;

  @override
  Widget build(BuildContext context) {
    final isFilled = selectedValue != null;

    return _EquationRow(
      children: [
        _EquationBeat(
          beatIndex: 0,
          child: showDigits
              ? _DigitValue(
                  color: getDigitDisplayColor(equation.knownPart),
                  fontSize: digitSize,
                  value: equation.knownPart,
                )
              : CompositionDotGroup(
                  count: equation.knownPart,
                  frameSize: dotSlotSize,
                ),
        ),
        _EquationBeat(
          beatIndex: 1,
          child: _OperatorSign(fontSize: operatorSize, text: '+'),
        ),
        _EquationBeat(
          beatIndex: 2,
          child: MissingSlot(
            key: slotKey,
            acceptDrops: acceptSlotDrops,
            child: isFilled
                ? _PracticeSlotContent(
                    dotSlotSize: dotSlotSize,
                    digitSize: digitSize,
                    showDigits: showDigits,
                    value: selectedValue!,
                  )
                : null,
            isFilled: isFilled,
            isShaking: isSlotShaking,
            onAccept: onSlotAccept,
            size: dotSlotSize,
          ),
        ),
        _EquationBeat(
          beatIndex: 3,
          child: _OperatorSign(fontSize: operatorSize, text: '='),
        ),
        _EquationBeat(
          beatIndex: 4,
          child: showDigits
              ? _DigitValue(
                  color: compositionWholeColor,
                  fontSize: digitSize,
                  value: equation.whole,
                )
              : CompositionDotGroup(
                  count: equation.whole,
                  dotColor: compositionWholeColor,
                  frameSize: dotSlotSize,
                ),
        ),
      ],
    );
  }
}

class _EquationRow extends StatelessWidget {
  const _EquationRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(width: 12),
              children[index],
            ],
          ],
        ),
      ),
    );
  }
}

class _PracticeSlotContent extends StatelessWidget {
  const _PracticeSlotContent({
    required this.value,
    required this.showDigits,
    required this.dotSlotSize,
    required this.digitSize,
  });

  final int value;
  final bool showDigits;
  final double dotSlotSize;
  final double digitSize;

  @override
  Widget build(BuildContext context) {
    if (showDigits) {
      return _DigitValue(
        color: getDigitDisplayColor(value),
        fontSize: digitSize,
        value: value,
      );
    }

    return CompositionDotGroup(
      count: value,
      frameSize: dotSlotSize * 0.85,
    );
  }
}

class _DigitValue extends StatelessWidget {
  const _DigitValue({
    required this.color,
    required this.fontSize,
    required this.value,
  });

  final Color color;
  final double fontSize;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _OperatorSign extends StatelessWidget {
  const _OperatorSign({
    required this.text,
    required this.fontSize,
  });

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1,
        color: const Color(0xFF94A3B8),
      ),
    );
  }
}

class _EquationBeat extends StatefulWidget {
  const _EquationBeat({
    required this.beatIndex,
    required this.child,
  });

  final int beatIndex;
  final Widget child;

  @override
  State<_EquationBeat> createState() => _EquationBeatState();
}

class _EquationBeatState extends State<_EquationBeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  Timer? _enterTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: compositionBeatPopMs),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    final delayMs = getCompositionBeatDelayMs(widget.beatIndex);
    if (delayMs <= 0) {
      _controller.value = 1;
      return;
    }

    _enterTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.88 + 0.12 * t,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
