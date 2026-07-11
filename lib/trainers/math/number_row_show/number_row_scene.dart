import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_colors.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_reveal.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_geometry.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_model.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_sizes.dart';

/// Web v2: `platform/src/trainers/math/number-row-show/number-row-scene.tsx`
class NumberRowScene extends StatefulWidget {
  const NumberRowScene({
    super.key,
    required this.studyDigit,
    required this.sceneKey,
  });

  final int studyDigit;
  final String sceneKey;

  @override
  State<NumberRowScene> createState() => _NumberRowSceneState();
}

class _NumberRowSceneState extends State<NumberRowScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _pulseStartTimer;
  var _isStudyPulseActive = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: numberRowStudyPulseMs),
    );
    _restartReveal();
  }

  @override
  void didUpdateWidget(NumberRowScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sceneKey != widget.sceneKey ||
        oldWidget.studyDigit != widget.studyDigit) {
      _restartReveal();
    }
  }

  void _restartReveal() {
    _pulseStartTimer?.cancel();
    _pulseController
      ..stop()
      ..value = 0;
    setState(() => _isStudyPulseActive = false);

    _pulseStartTimer = Timer(
      Duration(milliseconds: getNumberRowRevealTotalMs()),
      () {
        if (!mounted) {
          return;
        }
        setState(() => _isStudyPulseActive = true);
        _pulseController.repeat(reverse: true);
      },
    );
  }

  @override
  void dispose() {
    _pulseStartTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slots = getNumberRowSlots();
    final studyDigit = normalizeStudyDigit(widget.studyDigit);

    return SizedBox(
      width: NumberRowLayout.width,
      height: NumberRowLayout.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: NumberRowLayout.paddingX - 4,
            right: NumberRowLayout.paddingX - 4,
            top: NumberRowLayout.baselineY + 18,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: numberRowBaselineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          for (var index = 0; index < slots.length; index++)
            _DigitGlyph(
              key: ValueKey('${slots[index].digit}-${widget.sceneKey}'),
              digit: slots[index].digit,
              index: index,
              x: slots[index].x,
              y: NumberRowLayout.baselineY,
              isStudy: isStudyDigit(slots[index].digit, studyDigit),
              isStudyPulseActive: _isStudyPulseActive,
              pulse: _pulseController,
            ),
        ],
      ),
    );
  }
}

class _DigitGlyph extends StatefulWidget {
  const _DigitGlyph({
    super.key,
    required this.digit,
    required this.index,
    required this.x,
    required this.y,
    required this.isStudy,
    required this.isStudyPulseActive,
    required this.pulse,
  });

  final int digit;
  final int index;
  final double x;
  final double y;
  final bool isStudy;
  final bool isStudyPulseActive;
  final Animation<double> pulse;

  @override
  State<_DigitGlyph> createState() => _DigitGlyphState();
}

class _DigitGlyphState extends State<_DigitGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _enterProgress;
  Timer? _enterTimer;

  double get _fontSize =>
      widget.isStudy ? NumberRowLayout.activeFontSize : NumberRowLayout.inactiveFontSize;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: numberRowPopMs),
    );
    _enterProgress = CurvedAnimation(
      parent: _enterController,
      curve: numberRowPopCurve,
    );
    _scheduleEnterAnimation();
  }

  void _scheduleEnterAnimation() {
    final delayMs = getNumberRowRevealDelayMs(widget.index);
    if (delayMs <= 0) {
      _enterController.value = 1;
      return;
    }

    _enterTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _enterController.forward();
      }
    });
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isStudy ? getDigitDisplayColor(widget.digit) : numberRowInactiveColor;
    final fontWeight = widget.isStudy ? FontWeight.w800 : FontWeight.w600;

    return Positioned(
      left: widget.x,
      top: widget.y,
      child: AnimatedBuilder(
        animation: Listenable.merge([_enterProgress, widget.pulse]),
        builder: (context, child) {
          final enterT = _enterProgress.value.clamp(0.0, 1.0);
          final opacity = enterT;
          var scale = 0.88 + 0.12 * enterT;
          var offsetY = 0.0;

          if (widget.isStudy && widget.isStudyPulseActive) {
            final pulse = widget.pulse.value;
            scale *= 1 + pulse * 0.08;
            offsetY = -4 * math.sin(pulse * math.pi);
          }

          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, offsetY),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: Text(
                    '${widget.digit}',
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: fontWeight,
                      color: color,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
