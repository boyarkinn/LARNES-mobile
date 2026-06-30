import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_painter.dart';

class AbacusWidget extends StatefulWidget {
  const AbacusWidget({
    super.key,
    required this.rods,
    required this.totalRods,
    this.animate = true,
  });

  final List<RodState> rods;
  final int totalRods;
  final bool animate;

  @override
  State<AbacusWidget> createState() => _AbacusWidgetState();
}

class _AbacusWidgetState extends State<AbacusWidget>
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
  void didUpdateWidget(AbacusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rods == widget.rods && oldWidget.totalRods == widget.totalRods) {
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
    final viewBox = abacusViewBox(widget.totalRods);

    Widget painted(List<RodBeadLayout> layouts) {
      return SizedBox(
        width: viewBox.width,
        height: viewBox.height,
        child: CustomPaint(
          painter: AbacusPainter(
            rodLayouts: layouts,
            totalRods: widget.totalRods,
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

/// Показывает число на абакусе: сначала пустой, затем анимация к целевому.
class AnimatedAbacusValue extends StatefulWidget {
  const AnimatedAbacusValue({
    super.key,
    required this.value,
    required this.totalRods,
  });

  final int value;
  final int totalRods;

  @override
  State<AnimatedAbacusValue> createState() => _AnimatedAbacusValueState();
}

class _AnimatedAbacusValueState extends State<AnimatedAbacusValue> {
  late List<RodState> _rods;

  @override
  void initState() {
    super.initState();
    _rods = emptyRods(widget.totalRods);
    _scheduleTargetRods();
  }

  @override
  void didUpdateWidget(AnimatedAbacusValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value &&
        oldWidget.totalRods == widget.totalRods) {
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
    return AbacusWidget(
      rods: _rods,
      totalRods: widget.totalRods,
    );
  }
}
