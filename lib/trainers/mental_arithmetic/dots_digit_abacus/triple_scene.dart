import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_sizes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/triple_scene_layout.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/dot_group.dart';

/// Web: `triple-scene.tsx` visibility contract.
class TripleSceneVisibility {
  const TripleSceneVisibility({
    this.abacusPulseActive = false,
    this.digitPulseActive = false,
    this.showAbacus = false,
    this.showAbacusEquals = false,
    this.showDigit = false,
    this.showDigitEquals = false,
    this.showDots = false,
    this.visibleDotCount = 0,
  });

  final bool abacusPulseActive;
  final bool digitPulseActive;
  final bool showAbacus;
  final bool showAbacusEquals;
  final bool showDigit;
  final bool showDigitEquals;
  final bool showDots;
  final int visibleDotCount;

  TripleSceneVisibility copyWith({
    bool? abacusPulseActive,
    bool? digitPulseActive,
    bool? showAbacus,
    bool? showAbacusEquals,
    bool? showDigit,
    bool? showDigitEquals,
    bool? showDots,
    int? visibleDotCount,
  }) {
    return TripleSceneVisibility(
      abacusPulseActive: abacusPulseActive ?? this.abacusPulseActive,
      digitPulseActive: digitPulseActive ?? this.digitPulseActive,
      showAbacus: showAbacus ?? this.showAbacus,
      showAbacusEquals: showAbacusEquals ?? this.showAbacusEquals,
      showDigit: showDigit ?? this.showDigit,
      showDigitEquals: showDigitEquals ?? this.showDigitEquals,
      showDots: showDots ?? this.showDots,
      visibleDotCount: visibleDotCount ?? this.visibleDotCount,
    );
  }
}

/// Web v2: `platform/src/trainers/mental-arithmetic/dots-digit-abacus/triple-scene.tsx`
class TripleScene extends StatelessWidget {
  const TripleScene({super.key, required this.value, required this.visibility});

  final int value;
  final TripleSceneVisibility visibility;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = computeTripleSceneLayout(
          viewportWidth: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
          dotCount: value,
        );
        final rods = numberToAbacus(value, kDotsDigitAbacusTotalRods);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: _SceneBlock(
                    visible: visibility.showDots,
                    pulseActive: false,
                    child: DotGroup(
                      count: value,
                      frameWidth: layout.dotFrameWidth,
                      frameHeight: layout.dotFrameHeight,
                      visibleCount: visibility.visibleDotCount,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Center(
                child: _SceneBlock(
                  visible: visibility.showDigitEquals,
                  pulseActive: false,
                  child: _equalsSign(layout.equalsFontSize),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: _SceneBlock(
                    visible: visibility.showDigit,
                    pulseActive: visibility.digitPulseActive,
                    child: _digitCard(
                      layout.digitCardSize,
                      layout.digitFontSize,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Center(
                child: _SceneBlock(
                  visible: visibility.showAbacusEquals,
                  pulseActive: false,
                  child: _equalsSign(layout.equalsFontSize),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: _SceneBlock(
                    visible: visibility.showAbacus,
                    pulseActive: visibility.abacusPulseActive,
                    child: _abacusCard(
                      layout.abacusWidth,
                      layout.abacusHeight,
                      rods,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _equalsSign(double fontSize) {
    return Text(
      '=',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1,
        color: const Color(0xFFFB923C),
      ),
    );
  }

  Widget _digitCard(double cardSize, double fontSize) {
    return Container(
      key: const Key('triple-digit-card'),
      width: cardSize,
      height: cardSize,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1,
            color: const Color(0xFFEA580C),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _abacusCard(double width, double height, List<RodState> rods) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF7ED), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(
        height: height,
        child: AbacusWidget(
          activeBeadColor: Color(dotsDigitAbacusActiveBeadColor),
          rods: rods,
          totalRods: kDotsDigitAbacusTotalRods,
        ),
      ),
    );
  }
}

class _SceneBlock extends StatefulWidget {
  const _SceneBlock({
    required this.visible,
    required this.pulseActive,
    required this.child,
  });

  final bool visible;
  final bool pulseActive;
  final Widget child;

  @override
  State<_SceneBlock> createState() => _SceneBlockState();
}

class _SceneBlockState extends State<_SceneBlock>
    with SingleTickerProviderStateMixin {
  static const _popDurationMs = 400;
  static const _popScaleBegin = 0.92;
  static const _popOffsetY = 10.0;

  late final AnimationController _pulseController;
  var _revealed = false;
  var _enterProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: dotsDigitAbacusPulseCycleMs),
    );
    _revealed = widget.visible;
    if (_revealed) {
      _enterProgress = 1;
    }
    _syncPulse();
  }

  @override
  void didUpdateWidget(_SceneBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.visible && widget.visible) {
      _revealed = true;
      _runEnterAnimation();
    }
    _syncPulse();
  }

  void _runEnterAnimation() {
    _enterProgress = 0;
    const steps = 16;
    var step = 0;
    void tick() {
      if (!mounted) {
        return;
      }
      step += 1;
      setState(() {
        _enterProgress = Curves.easeOutBack.transform(step / steps);
      });
      if (step < steps) {
        Future<void>.delayed(
          Duration(milliseconds: _popDurationMs ~/ steps),
          tick,
        );
      }
    }

    tick();
  }

  void _syncPulse() {
    if (widget.pulseActive) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return const SizedBox.shrink();
    }

    final opacity = _enterProgress;
    final offsetY = _popOffsetY * (1 - _enterProgress);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final animatedPulseScale = widget.pulseActive
            ? 1 + _pulseController.value * 0.04
            : 1.0;
        final animatedScale =
            (_popScaleBegin + (1 - _popScaleBegin) * _enterProgress) *
            animatedPulseScale;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: Transform.scale(scale: animatedScale, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}
