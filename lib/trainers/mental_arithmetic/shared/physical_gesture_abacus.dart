import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

/// Shared scene binding: owns playback lifecycle and paints only the abacus.
class PhysicalGestureAbacus extends StatefulWidget {
  const PhysicalGestureAbacus({
    super.key,
    required this.plan,
    required this.speed,
    this.autoPlay = true,
    this.onComplete,
  });

  final PhysicalGesturePlan plan;
  final PhysicalGestureSpeed speed;
  final bool autoPlay;
  final VoidCallback? onComplete;

  @override
  State<PhysicalGestureAbacus> createState() => _PhysicalGestureAbacusState();
}

class _PhysicalGestureAbacusState extends State<PhysicalGestureAbacus> {
  late List<RodState> _rods;
  PhysicalGesturePlayer? _player;
  bool? _reducedMotion;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _rods = List.of(widget.plan.initialRods);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_player == null || _reducedMotion != reduced) {
      _configure(reducedMotion: reduced, preservePosition: _player != null);
    }
  }

  @override
  void didUpdateWidget(PhysicalGestureAbacus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan != widget.plan) _completed = false;
    if (oldWidget.plan != widget.plan ||
        oldWidget.speed != widget.speed ||
        oldWidget.autoPlay != widget.autoPlay) {
      _configure(
        reducedMotion: _reducedMotion ?? false,
        preservePosition: oldWidget.plan == widget.plan,
      );
    }
  }

  void _configure({
    required bool reducedMotion,
    required bool preservePosition,
  }) {
    final oldPosition = preservePosition ? _player?.position ?? 0 : 0;
    _player?.cancel();
    _reducedMotion = reducedMotion;
    final player = PhysicalGesturePlayer(
      plan: widget.plan,
      speed: widget.speed,
      reducedMotion: reducedMotion,
      onFrame: (frame, _) {
        if (mounted) setState(() => _rods = frame.rods);
      },
      onComplete: () {
        if (!mounted || _completed) return;
        _completed = true;
        widget.onComplete?.call();
      },
    );
    final position = oldPosition.clamp(0, player.frames.length);
    player.seek(position);
    _rods = position == 0
        ? List.of(widget.plan.initialRods)
        : player.frames[position - 1].rods;
    _player = player;
    if (widget.autoPlay && player.frames.isNotEmpty && !_completed) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(_player, player)) player.play();
      });
    }
  }

  @override
  void dispose() {
    _player?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timing = physicalGestureTiming(
      widget.speed,
      reducedMotion: _reducedMotion ?? false,
      baseTransitionMs: widget.plan.beadTransitionMs ?? 500,
    );
    return AbacusWidget(
      rods: _rods,
      totalRods: widget.plan.initialRods.length,
      beadAnimationDuration: Duration(milliseconds: timing.transitionMs),
    );
  }
}
