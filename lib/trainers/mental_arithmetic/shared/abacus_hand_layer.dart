import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_hand_motion.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:rive/rive.dart' as rive;

enum HandMotionPhase { idle, prepare, move, returning }

/// Transparent Rive overlay driven by the same physical gesture frames as the beads.
class AbacusHandLayer extends StatefulWidget {
  const AbacusHandLayer({
    super.key,
    required this.motions,
    required this.phase,
    required this.sequence,
    required this.moveMs,
    required this.prepareMs,
    required this.returnMs,
    required this.abacusWidth,
    required this.abacusHeight,
    this.restShiftY = 0,
    this.onLoadComplete,
  });

  final List<AbacusHandMotion> motions;
  final HandMotionPhase phase;
  final int sequence;
  final int moveMs;
  final int prepareMs;
  final int returnMs;
  final double abacusWidth;
  final double abacusHeight;
  final double restShiftY;
  final ValueChanged<bool>? onLoadComplete;

  @override
  State<AbacusHandLayer> createState() => _AbacusHandLayerState();
}

class _AbacusHandLayerState extends State<AbacusHandLayer> {
  rive.File? _file;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final file = await rive.File.asset(
        'assets/animations/abacus-hand.riv',
        riveFactory: rive.Factory.rive,
      );
      if (!mounted) {
        file?.dispose();
        return;
      }
      if (file == null) {
        widget.onLoadComplete?.call(false);
        return;
      }
      setState(() => _file = file);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLoadComplete?.call(true);
      });
    } catch (error) {
      debugPrint('Abacus hand Rive load failed: $error');
      if (mounted) widget.onLoadComplete?.call(false);
    }
  }

  @override
  void dispose() {
    final file = _file;
    // Child controllers dispose during this unmount; release the shared file afterwards.
    if (file != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => file.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    if (file == null) {
      return IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final hand in AbacusHand.values)
              _IdleHandImage(
                hand: hand,
                rect: handIdleImageRect(
                  hand,
                  widget.abacusWidth,
                  widget.abacusHeight,
                  widget.restShiftY,
                ),
              ),
          ],
        ),
      );
    }
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final hand in AbacusHand.values)
            _RiveHand(
              key: ValueKey(hand),
              file: file,
              hand: hand,
              motion: widget.motions
                  .where((motion) => motion.hand == hand)
                  .firstOrNull,
              phase: widget.phase,
              sequence: widget.sequence,
              moveMs: widget.moveMs,
              prepareMs: widget.prepareMs,
              returnMs: widget.returnMs,
              idleOrigin: handRestOrigin(
                hand,
                widget.abacusWidth,
                widget.abacusHeight,
                widget.restShiftY,
              ),
            ),
        ],
      ),
    );
  }
}

class _IdleHandImage extends StatelessWidget {
  const _IdleHandImage({required this.hand, required this.rect});

  final AbacusHand hand;
  final Rect rect;

  @override
  Widget build(BuildContext context) => Positioned(
    left: rect.left,
    top: rect.top,
    width: rect.width,
    height: rect.height,
    child: Image.asset(
      hand == AbacusHand.left
          ? 'assets/animations/hand-idle-left.png'
          : 'assets/animations/hand-idle-right.png',
      fit: BoxFit.fill,
    ),
  );
}

class _RiveHand extends StatefulWidget {
  const _RiveHand({
    super.key,
    required this.file,
    required this.hand,
    required this.motion,
    required this.phase,
    required this.sequence,
    required this.moveMs,
    required this.prepareMs,
    required this.returnMs,
    required this.idleOrigin,
  });

  final rive.File file;
  final AbacusHand hand;
  final AbacusHandMotion? motion;
  final HandMotionPhase phase;
  final int sequence;
  final int moveMs;
  final int prepareMs;
  final int returnMs;
  final Offset idleOrigin;

  @override
  State<_RiveHand> createState() => _RiveHandState();
}

class _RiveHandState extends State<_RiveHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timeline;
  late final rive.RiveWidgetController _rive;
  late final rive.ViewModelInstance _viewModel;
  final Map<String, rive.ViewModelInstanceNumber> _numbers = {};
  HandRig? _rig;
  HandRig? _previousRig;
  AbacusHandPose? _pose;
  AbacusHandPose? _previousPose;
  double _scale = handParkScale;
  double _previousScale = handParkScale;

  @override
  void initState() {
    super.initState();
    _rive = rive.RiveWidgetController(
      widget.file,
      artboardSelector: rive.ArtboardSelector.byName('Hand'),
      stateMachineSelector: rive.StateMachineSelector.byName('Hand idle'),
    );
    _viewModel = _rive.dataBind(rive.DataBind.auto());
    for (final name in [
      'indexX',
      'indexY',
      'thumbX',
      'thumbY',
      'openOpacity',
      'openContactOpacity',
      'openMiddleOpacity',
      'fistOpacity',
      'indexOpacity',
      'crabSpreadOpacity',
      'crabMiddleOpacity',
      'crabWorkingOpacity',
      'crabTouchOpacity',
      'quarterOpacity',
      'midOpacity',
      'threeQuarterOpacity',
      'idleLeftOpacity',
      'idleRightOpacity',
      'idleTransitionOpacity',
    ]) {
      final property = _viewModel.number(name);
      if (property != null) _numbers[name] = property;
    }
    _timeline = AnimationController(vsync: this)..addListener(_tick);
    _start();
  }

  @override
  void didUpdateWidget(_RiveHand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sequence != oldWidget.sequence ||
        widget.motion != oldWidget.motion ||
        widget.phase != oldWidget.phase ||
        widget.idleOrigin != oldWidget.idleOrigin) {
      _start();
    }
  }

  String get _idleOpacityName =>
      widget.hand == AbacusHand.left ? 'idleLeftOpacity' : 'idleRightOpacity';

  HandRig _idleRig() => HandRig(
    origin: widget.idleOrigin,
    indexX: 0,
    indexY: 0,
    thumbX: 0,
    thumbY: 0,
  );

  void _start() {
    final motion = widget.motion;
    if (widget.phase == HandMotionPhase.idle || motion == null) {
      _timeline.stop();
      _rig = _idleRig();
      _previousRig = null;
      _previousPose = null;
      _pose = null;
      _scale = handParkScale;
      _previousScale = handParkScale;
      _writeControls(_rig!, {_idleOpacityName: 1});
      return;
    }
    _previousRig = _rig ?? _idleRig();
    _previousScale = _scale;
    _previousPose = _pose;
    _pose = widget.phase == HandMotionPhase.returning ? null : motion.pose;
    final durationMs = switch (widget.phase) {
      HandMotionPhase.prepare => widget.prepareMs,
      HandMotionPhase.returning => widget.returnMs,
      _ => widget.moveMs,
    };
    _timeline.duration = Duration(milliseconds: durationMs.clamp(1, 10000));
    _timeline.forward(from: 0);
    _tick();
  }

  String _opacityName(AbacusHandPose pose) => switch (pose) {
    AbacusHandPose.openMiddle => 'openMiddleOpacity',
    AbacusHandPose.fist => 'fistOpacity',
    AbacusHandPose.indexOnly => 'indexOpacity',
    AbacusHandPose.crabSpread => 'crabSpreadOpacity',
    AbacusHandPose.crabMiddle => 'crabMiddleOpacity',
    AbacusHandPose.crabWorking => 'crabWorkingOpacity',
  };

  Map<String, double> _travelWeights(String from, String to, double progress) {
    if (progress >= 1) return {to: 1};
    if (progress <= 0) return {from: 1};
    if (progress < 0.5) {
      return {from: 1 - progress * 2, 'idleTransitionOpacity': progress * 2};
    }
    return {'idleTransitionOpacity': (1 - progress) * 2, to: progress * 2 - 1};
  }

  Map<String, double> _poseWeights(double progress) {
    if (widget.phase == HandMotionPhase.idle || widget.motion == null) {
      return {_idleOpacityName: 1};
    }
    if (widget.phase == HandMotionPhase.returning) {
      final previous = _previousPose;
      return previous == null
          ? {_idleOpacityName: 1}
          : _travelWeights(_opacityName(previous), _idleOpacityName, progress);
    }
    final pose = _pose!;
    final previous = _previousPose;
    if (widget.phase == HandMotionPhase.prepare && previous == null) {
      return _travelWeights(_idleOpacityName, _opacityName(pose), progress);
    }
    if (previous == null || previous == pose || progress >= 1) {
      return {_opacityName(pose): 1};
    }
    final stages =
        previous == AbacusHandPose.fist && pose == AbacusHandPose.openMiddle
        ? [
            'fistOpacity',
            'threeQuarterOpacity',
            'midOpacity',
            'quarterOpacity',
            'openMiddleOpacity',
          ]
        : previous == AbacusHandPose.openMiddle && pose == AbacusHandPose.fist
        ? [
            'openMiddleOpacity',
            'quarterOpacity',
            'midOpacity',
            'threeQuarterOpacity',
            'fistOpacity',
          ]
        : null;
    if (stages == null) {
      return {
        _opacityName(previous): 1 - progress,
        _opacityName(pose): progress,
      };
    }
    final position = progress * (stages.length - 1);
    final first = position.floor().clamp(0, stages.length - 2);
    final fraction = position - first;
    return {stages[first]: 1 - fraction, stages[first + 1]: fraction};
  }

  HandRig _lerpRig(HandRig from, HandRig to, double progress) => HandRig(
    origin: Offset.lerp(from.origin, to.origin, progress)!,
    indexX: from.indexX + (to.indexX - from.indexX) * progress,
    indexY: from.indexY + (to.indexY - from.indexY) * progress,
    thumbX: from.thumbX + (to.thumbX - from.thumbX) * progress,
    thumbY: from.thumbY + (to.thumbY - from.thumbY) * progress,
  );

  void _writeControls(HandRig rig, Map<String, double> weights) {
    final values = <String, double>{
      for (final name in _numbers.keys) name: 0,
      'indexX': rig.indexX,
      'indexY': rig.indexY,
      'thumbX': rig.thumbX,
      'thumbY': rig.thumbY,
      ...weights,
    };
    for (final entry in values.entries) {
      final number = _numbers[entry.key];
      if (number != null && (number.value - entry.value).abs() > 0.0001) {
        number.value = entry.value;
      }
    }
  }

  void _tick() {
    final motion = widget.motion;
    if (!mounted || motion == null || widget.phase == HandMotionPhase.idle) {
      return;
    }
    final elapsed = _timeline.value;
    final previous = _previousRig ?? _idleRig();
    late final HandRig target;
    late final double positionProgress;
    late final double poseProgress;
    switch (widget.phase) {
      case HandMotionPhase.prepare:
        target = handRigAt(motion, 0);
        positionProgress = Curves.easeOut.transform(elapsed);
        poseProgress = positionProgress;
      case HandMotionPhase.move:
        target = handRigAt(motion, Curves.easeOutBack.transform(elapsed));
        positionProgress = Curves.easeOut.transform(
          (elapsed / 0.18).clamp(0.0, 1.0),
        );
        poseProgress = (elapsed / 0.18).clamp(0.0, 1.0);
      case HandMotionPhase.returning:
        target = _idleRig();
        positionProgress = Curves.easeInOut.transform(elapsed);
        poseProgress = positionProgress;
      case HandMotionPhase.idle:
        return;
    }
    final rig = _lerpRig(previous, target, positionProgress);
    _writeControls(rig, _poseWeights(poseProgress));
    final targetScale = widget.phase == HandMotionPhase.returning
        ? handParkScale
        : 1.0;
    setState(() {
      _rig = rig;
      _scale =
          _previousScale + (targetScale - _previousScale) * positionProgress;
    });
  }

  @override
  void dispose() {
    _timeline.dispose();
    for (final number in _numbers.values) {
      number.dispose();
    }
    _viewModel.dispose();
    _rive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final origin = _rig?.origin ?? widget.idleOrigin;
    return Positioned(
      left: origin.dx,
      top: origin.dy,
      width: handArtboardSize.width * _scale,
      height: handArtboardSize.height * _scale,
      child: Transform.flip(
        flipX: widget.hand == AbacusHand.left,
        child: rive.RiveWidget(controller: _rive, fit: rive.Fit.contain),
      ),
    );
  }
}
