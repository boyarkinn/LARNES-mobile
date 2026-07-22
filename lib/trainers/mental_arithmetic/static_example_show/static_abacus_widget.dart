import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/move_hints.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/static_abacus_painter.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/static_example_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

class StaticAbacusWidget extends StatefulWidget {
  const StaticAbacusWidget({
    super.key,
    required this.rods,
    required this.totalRods,
    this.moveOverlays = const [],
    this.animate = true,
  });

  final List<RodState> rods;
  final int totalRods;
  final List<MoveOverlay> moveOverlays;
  final bool animate;

  @override
  State<StaticAbacusWidget> createState() => _StaticAbacusWidgetState();
}

class _StaticAbacusWidgetState extends State<StaticAbacusWidget>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 500);

  late List<RodBeadLayout> _fromLayouts;
  late List<RodBeadLayout> _toLayouts;
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _toLayouts = layoutsForRods(widget.rods);
    _fromLayouts = _toLayouts;
    if (widget.animate) {
      _controller = AnimationController(vsync: this, duration: _duration)
        ..value = 1;
    }
  }

  @override
  void didUpdateWidget(StaticAbacusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rods == widget.rods &&
        oldWidget.totalRods == widget.totalRods &&
        oldWidget.moveOverlays == widget.moveOverlays) {
      return;
    }

    _fromLayouts = _displayLayouts;
    _toLayouts = layoutsForRods(widget.rods);

    if (!widget.animate || _controller == null) {
      setState(() {});
      return;
    }

    _controller!
      ..stop()
      ..value = 0
      ..forward();
  }

  List<RodBeadLayout> get _displayLayouts {
    if (_controller == null || _controller!.isCompleted) {
      return _toLayouts;
    }
    final t = Curves.easeOutBack.transform(_controller!.value).clamp(0.0, 1.0);
    return lerpRodLayouts(_fromLayouts, _toLayouts, t);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewBox = abacusViewBoxWithMoveOverlays(
      widget.totalRods,
      widget.moveOverlays,
      widget.rods,
    );
    final overlayLayouts = widget.moveOverlays.isEmpty
        ? const <MoveOverlayLayout>[]
        : layoutMoveOverlays(widget.moveOverlays, widget.rods, widget.totalRods);

    Widget painted(List<RodBeadLayout> layouts) {
      return SizedBox(
        width: viewBox.viewBoxWidth,
        height: viewBox.base.height,
        child: CustomPaint(
          painter: StaticAbacusPainter(
            rodLayouts: layouts,
            totalRods: widget.totalRods,
            viewBox: viewBox,
            overlayLayouts: overlayLayouts,
          ),
        ),
      );
    }

    if (_controller == null) {
      return FittedBox(child: painted(_toLayouts));
    }

    return FittedBox(
      child: AnimatedBuilder(
        animation: _controller!,
        builder: (context, child) => painted(_displayLayouts),
      ),
    );
  }
}

class AnimatedStaticAbacusValue extends StatefulWidget {
  const AnimatedStaticAbacusValue({
    super.key,
    required this.value,
    required this.totalRods,
    this.moveOverlays = const [],
  });

  final int value;
  final int totalRods;
  final List<MoveOverlay> moveOverlays;

  @override
  State<AnimatedStaticAbacusValue> createState() => _AnimatedStaticAbacusValueState();
}

class _AnimatedStaticAbacusValueState extends State<AnimatedStaticAbacusValue> {
  late List<RodState> _rods;

  @override
  void initState() {
    super.initState();
    _rods = emptyRods(widget.totalRods);
    _scheduleTargetRods();
  }

  @override
  void didUpdateWidget(AnimatedStaticAbacusValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value &&
        oldWidget.totalRods == widget.totalRods &&
        oldWidget.moveOverlays == widget.moveOverlays) {
      return;
    }

    setState(() => _rods = emptyRods(widget.totalRods));
    _scheduleTargetRods();
  }

  void _scheduleTargetRods() {
    final targetRods = numberToAbacus(widget.value, widget.totalRods);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _rods = targetRods);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StaticAbacusWidget(
      rods: _rods,
      totalRods: widget.totalRods,
      moveOverlays: widget.moveOverlays,
    );
  }
}
