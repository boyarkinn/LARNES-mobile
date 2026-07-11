import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dot_reveal.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/triple_scene_layout.dart';
import 'package:larnes_mobile/trainers/shared/dot_group.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

/// Web v2: `platform/src/trainers/mental-arithmetic/dots-digit-abacus/triple-scene.tsx`
class TripleScene extends StatefulWidget {
  const TripleScene({
    super.key,
    required this.totalRods,
    required this.value,
  });

  final int totalRods;
  final int value;

  @override
  State<TripleScene> createState() => _TripleSceneState();
}

class _TripleSceneState extends State<TripleScene>
    with SingleTickerProviderStateMixin {
  static const _staggerMs = 450;
  static const _itemDurationMs = 400;

  AnimationController? _controller;
  List<RodState> _abacusRods = [];
  Timer? _abacusTimer;

  @override
  void initState() {
    super.initState();
    _abacusRods = emptyRods(widget.totalRods);
    _restartScene();
  }

  @override
  void didUpdateWidget(TripleScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value &&
        oldWidget.totalRods == widget.totalRods) {
      return;
    }

    _restartScene();
  }

  void _restartScene() {
    _abacusTimer?.cancel();
    _controller?.dispose();

    setState(() => _abacusRods = emptyRods(widget.totalRods));

    final totalDuration = _totalAnimDuration(widget.value);
    _controller = AnimationController(vsync: this, duration: totalDuration)
      ..forward();

    _abacusTimer = Timer(
      Duration(
        milliseconds: getDotPhaseDurationMs(widget.value) + _staggerMs * 4,
      ),
      () {
        if (!mounted) {
          return;
        }
        setState(
          () => _abacusRods = numberToAbacus(widget.value, widget.totalRods),
        );
      },
    );
  }

  @override
  void dispose() {
    _abacusTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Duration _totalAnimDuration(int value) {
    return Duration(
      milliseconds:
          getDotPhaseDurationMs(value) + _staggerMs * 4 + _itemDurationMs,
    );
  }

  int _beatDelayMs(int value, int beatIndex) {
    if (beatIndex == 0) {
      return 0;
    }
    return getDotPhaseDurationMs(value) + _staggerMs * beatIndex;
  }

  double _itemProgress(int value, int beatIndex) {
    final controller = _controller;
    if (controller == null || controller.duration == null) {
      return 0;
    }

    final total = controller.duration!.inMilliseconds;
    final start = _beatDelayMs(value, beatIndex) / total;
    final end = start + _itemDurationMs / total;
    final t = ((controller.value - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(t).clamp(0.0, 1.0);
  }

  Widget _staggeredItem(int beatIndex, Widget child) {
    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, _) {
        final progress = _itemProgress(widget.value, beatIndex);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - progress)),
            child: Transform.scale(
              scale: 0.92 + 0.08 * progress,
              child: child,
            ),
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
          '${widget.value}',
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

  Widget _abacusCard(double width, double height) {
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
          rods: _abacusRods,
          totalRods: widget.totalRods,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;
        final viewportWidth = constraints.maxWidth;
        final layout = computeTripleSceneLayout(
          viewportWidth: viewportWidth,
          viewportHeight: viewportHeight,
          dotCount: widget.value,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: _staggeredItem(
                    0,
                    DotGroup(
                      count: widget.value,
                      revealProgressively: true,
                      frameWidth: layout.dotFrameWidth,
                      frameHeight: layout.dotFrameHeight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Center(
                child: _staggeredItem(1, _equalsSign(layout.equalsFontSize)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: _staggeredItem(
                    2,
                    _digitCard(layout.digitCardSize, layout.digitFontSize),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Center(
                child: _staggeredItem(3, _equalsSign(layout.equalsFontSize)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: _staggeredItem(
                    4,
                    _abacusCard(layout.abacusWidth, layout.abacusHeight),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
