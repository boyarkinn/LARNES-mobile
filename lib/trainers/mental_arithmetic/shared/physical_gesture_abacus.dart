import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_hand_motion.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_hand_layer.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

const _handApproachMs = 300;
const _riveSplashWait = Duration(seconds: 3);

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
    this.tempoMultiplier = 1,
    this.initialCheckpointStep,
    this.onCheckpoint,
  });

  final PhysicalGesturePlan plan;
  final PhysicalGestureSpeed speed;
  final bool autoPlay;
  final VoidCallback? onComplete;
  final Future<void> Function(String key, GestureCueSignal signal)? onCue;
  final bool showHands;
  final double tempoMultiplier;
  final int? initialCheckpointStep;
  final void Function(int stepIndex, int framePosition, bool completed)?
  onCheckpoint;

  @override
  State<PhysicalGestureAbacus> createState() => _PhysicalGestureAbacusState();
}

class _PhysicalGestureAbacusState extends State<PhysicalGestureAbacus> {
  late List<RodState> _rods;
  PhysicalGesturePlayer? _player;
  bool? _reducedMotion;
  bool _completed = false;
  List<AbacusHandMotion> _handMotions = const [];
  HandMotionPhase _handPhase = HandMotionPhase.idle;
  int _handSequence = -1;
  double _activeTempoMultiplier = 1;
  bool _handAssetsReady = false;
  bool _autoplayStarted = false;
  Timer? _riveSplashTimer;

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
    if (oldWidget.showHands != widget.showHands) {
      _riveSplashTimer?.cancel();
      _riveSplashTimer = null;
      if (widget.showHands) _handAssetsReady = false;
    }
    if (oldWidget.plan != widget.plan ||
        oldWidget.speed != widget.speed ||
        oldWidget.tempoMultiplier != widget.tempoMultiplier ||
        oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.showHands != widget.showHands) {
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
    final oldCheckpoint =
        (preservePosition ? _player?.checkpointStepIndex : null) ??
        widget.initialCheckpointStep;
    _player?.cancel();
    _reducedMotion = reducedMotion;
    _handMotions = const [];
    _handPhase = HandMotionPhase.idle;
    _handSequence = -1;
    _activeTempoMultiplier = 1;
    _autoplayStarted = false;
    final player = PhysicalGesturePlayer(
      plan: widget.plan,
      speed: widget.speed,
      tempoMultiplier: widget.tempoMultiplier,
      reducedMotion: reducedMotion,
      prepareMs: _handApproachMs,
      onFrame: (frame, _) {
        if (!mounted) return;
        setState(() {
          _activeTempoMultiplier = frame.tempoMultiplier;
          if (widget.showHands && !reducedMotion) {
            _handMotions = frame.moves.isEmpty
                ? const []
                : handMotionsForFrame(_rods, frame);
            _handPhase = frame.moves.isEmpty
                ? HandMotionPhase.idle
                : HandMotionPhase.move;
            _handSequence++;
          }
          _rods = frame.rods;
        });
      },
      onPrepare: widget.showHands && !reducedMotion
          ? (frame, _) {
              if (!mounted) return;
              setState(() {
                _activeTempoMultiplier = frame.tempoMultiplier;
                _handMotions = handMotionsForFrame(_rods, frame);
                _handPhase = HandMotionPhase.prepare;
                _handSequence++;
              });
            }
          : null,
      onReturn: widget.showHands && !reducedMotion
          ? (frame, _) {
              if (!mounted) return;
              setState(() {
                _activeTempoMultiplier = frame.tempoMultiplier;
                _handPhase = HandMotionPhase.returning;
                _handSequence++;
              });
            }
          : null,
      onReset: (rods, _) {
        if (!mounted) return;
        setState(() {
          _rods = rods;
          _handMotions = const [];
          _handPhase = HandMotionPhase.idle;
          _handSequence++;
        });
      },
      onCue: widget.onCue,
      onCheckpoint: (step, position, completed) =>
          widget.onCheckpoint?.call(step, position, completed),
      onComplete: () {
        if (!mounted || _completed) return;
        _completed = true;
        widget.onComplete?.call();
      },
    );
    if (oldCheckpoint != null) {
      player.seekToStep(oldCheckpoint.clamp(-1, widget.plan.steps.length));
    }
    _rods = player.checkpointRods;
    _player = player;
    if (widget.autoPlay && player.hasEvents && !_completed) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _startIfReady(player);
      });
    }
  }

  void _startIfReady(PhysicalGesturePlayer player) {
    if (!mounted ||
        !identical(_player, player) ||
        _autoplayStarted ||
        !widget.autoPlay ||
        !player.hasEvents ||
        _completed ||
        (widget.showHands && !_handAssetsReady)) {
      return;
    }
    _autoplayStarted = true;
    player.play();
  }

  void _onHandLoadComplete(bool loaded) {
    _riveSplashTimer?.cancel();
    _riveSplashTimer = null;
    if (!loaded) {
      _handAssetsReady = true;
      final player = _player;
      if (player != null) _startIfReady(player);
      return;
    }
    _riveSplashTimer = Timer(_riveSplashWait, () {
      if (!mounted || !widget.showHands) return;
      _handAssetsReady = true;
      final player = _player;
      if (player != null) _startIfReady(player);
    });
  }

  @override
  void dispose() {
    _riveSplashTimer?.cancel();
    _player?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timing = physicalGestureTiming(
      widget.speed,
      reducedMotion: _reducedMotion ?? false,
      baseTransitionMs: widget.plan.beadTransitionMs ?? 500,
      tempoMultiplier: widget.tempoMultiplier * _activeTempoMultiplier,
    );
    final abacus = AbacusWidget(
      rods: _rods,
      totalRods: widget.plan.initialRods.length,
      beadAnimationDuration: Duration(milliseconds: timing.transitionMs),
    );
    if (!widget.showHands) return abacus;
    final viewBox = abacusViewBox(widget.plan.initialRods.length);
    final stageHeight = viewBox.height + handRestBandHeight;
    return LayoutBuilder(
      builder: (context, viewport) {
        final scale = math.min(
          viewport.maxWidth / viewBox.width,
          viewport.maxHeight / stageHeight,
        );
        final stageTop = (viewport.maxHeight - stageHeight * scale) / 2;
        final idleImageBottom = handIdleImageRect(
          AbacusHand.left,
          viewBox.width,
          viewBox.height,
        ).bottom;
        final restShiftY = scale > 0
            ? math.max(
                0.0,
                (viewport.maxHeight - stageTop) / scale - idleImageBottom,
              )
            : 0.0;
        return ClipRect(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              clipBehavior: Clip.none,
              child: SizedBox(
                width: viewBox.width,
                height: stageHeight,
                child: Stack(
                  // Keep the abacus fitted. Only the trainer viewport crops
                  // hands as they travel or extend past the rest band.
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      width: viewBox.width,
                      height: viewBox.height,
                      child: abacus,
                    ),
                    Positioned.fill(
                      child: AbacusHandLayer(
                        motions: _handMotions,
                        phase: _handPhase,
                        sequence: _handSequence,
                        moveMs: timing.transitionMs,
                        prepareMs: timing.pauseMs(_handApproachMs),
                        returnMs: timing.pauseMs(320),
                        abacusWidth: viewBox.width,
                        abacusHeight: viewBox.height,
                        restShiftY: restShiftY,
                        onLoadComplete: _onHandLoadComplete,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
