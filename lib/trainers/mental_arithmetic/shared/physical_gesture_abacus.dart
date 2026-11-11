import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_hand_motion.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_hand_layer.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

/// Shared scene binding: owns playback and overlays optional physical hands.
class PhysicalGestureAbacus extends StatefulWidget {
  const PhysicalGestureAbacus({
    super.key,
    required this.plan,
    required this.speed,
    this.autoPlay = true,
    this.onComplete,
    this.onCue,
    this.showHands = false,
  });

  final PhysicalGesturePlan plan;
  final PhysicalGestureSpeed speed;
  final bool autoPlay;
  final VoidCallback? onComplete;
  final Future<void> Function(String key, GestureCueSignal signal)? onCue;
  final bool showHands;

  @override
  State<PhysicalGestureAbacus> createState() => _PhysicalGestureAbacusState();
}

class _PhysicalGestureAbacusState extends State<PhysicalGestureAbacus> {
  late List<RodState> _rods;
  PhysicalGesturePlayer? _player;
  bool? _reducedMotion;
  bool _completed = false;
  List<AbacusHandMotion> _handMotions = const [];
  HandMotionPhase _handPhase = HandMotionPhase.prepare;
  int _handSequence = -1;

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
    _handMotions = const [];
    _handSequence = -1;
    final player = PhysicalGesturePlayer(
      plan: widget.plan,
      speed: widget.speed,
      reducedMotion: reducedMotion,
      onFrame: (frame, _) {
        if (!mounted) return;
        setState(() {
          if (widget.showHands && !reducedMotion) {
            _handMotions = handMotionsForFrame(_rods, frame);
            _handPhase = HandMotionPhase.move;
            _handSequence++;
          }
          _rods = frame.rods;
        });
      },
      onPrepare: widget.showHands && !reducedMotion
          ? (frame, _) {
              if (!mounted) return;
              setState(() {
                _handMotions = handMotionsForFrame(_rods, frame);
                _handPhase = HandMotionPhase.prepare;
                _handSequence++;
              });
            }
          : null,
      onCue: widget.onCue,
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
    final abacus = AbacusWidget(
      rods: _rods,
      totalRods: widget.plan.initialRods.length,
      beadAnimationDuration: Duration(milliseconds: timing.transitionMs),
    );
    if (!widget.showHands || (_reducedMotion ?? false)) return abacus;
    final viewBox = abacusViewBox(widget.plan.initialRods.length);
    return FittedBox(
      child: SizedBox(
        width: viewBox.width,
        height: viewBox.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: abacus),
            Positioned.fill(
              child: AbacusHandLayer(
                motions: _handMotions,
                phase: _handPhase,
                sequence: _handSequence,
                moveMs: timing.transitionMs,
                prepareMs: timing.pauseMs(120),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
