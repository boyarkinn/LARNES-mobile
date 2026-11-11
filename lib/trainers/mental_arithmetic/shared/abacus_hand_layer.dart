import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_hand_motion.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:rive/rive.dart' as rive;

enum HandMotionPhase { prepare, move }

/// Transparent Rive overlay driven by the same physical gesture frames as the beads.
class AbacusHandLayer extends StatefulWidget {
  const AbacusHandLayer({
    super.key,
    required this.motions,
    required this.phase,
    required this.sequence,
    required this.moveMs,
    required this.prepareMs,
  });

  final List<AbacusHandMotion> motions;
  final HandMotionPhase phase;
  final int sequence;
  final int moveMs;
  final int prepareMs;

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
      setState(() => _file = file);
    } catch (error) {
      debugPrint('Abacus hand Rive load failed: $error');
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
    if (file == null) return const SizedBox.shrink();
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
            ),
        ],
      ),
    );
  }
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
  });

  final rive.File file;
  final AbacusHand hand;
  final AbacusHandMotion? motion;
  final HandMotionPhase phase;
  final int sequence;
  final int moveMs;
  final int prepareMs;

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
  double _opacity = 0;

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
        widget.phase != oldWidget.phase) {
      _start();
    }
  }

  void _start() {
    final motion = widget.motion;
    if (motion == null) {
      _timeline.stop();
      if (_opacity != 0) setState(() => _opacity = 0);
      return;
    }
    _previousRig = _rig;
    _previousPose = _pose;
    _pose = motion.pose;
    _timeline.duration = Duration(
      milliseconds:
          (widget.phase == HandMotionPhase.prepare
                  ? widget.prepareMs
                  : widget.moveMs)
              .clamp(1, 10000),
    );
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

  Map<String, double> _poseWeights(double progress) {
    final pose = _pose!;
    final previous = _previousPose;
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

  void _tick() {
    final motion = widget.motion;
    if (!mounted || motion == null) return;
    final elapsed = _timeline.value;
    final eased = widget.phase == HandMotionPhase.prepare
        ? Curves.easeOut.transform(elapsed)
        : Curves.easeOutBack.transform(elapsed);
    final target = handRigAt(
      motion,
      widget.phase == HandMotionPhase.prepare ? 0 : eased,
    );
    final previous = _previousRig;
    final approach = widget.phase == HandMotionPhase.prepare
        ? 1 - eased
        : (1 - Curves.easeOut.transform((elapsed / 0.18).clamp(0.0, 1.0)));
    final rig = previous == null
        ? target
        : HandRig(
            origin: Offset.lerp(target.origin, previous.origin, approach)!,
            indexX:
                target.indexX + (previous.indexX - target.indexX) * approach,
            indexY:
                target.indexY + (previous.indexY - target.indexY) * approach,
            thumbX:
                target.thumbX + (previous.thumbX - target.thumbX) * approach,
            thumbY:
                target.thumbY + (previous.thumbY - target.thumbY) * approach,
          );
    final values = <String, double>{
      for (final name in _numbers.keys) name: 0,
      'indexX': rig.indexX,
      'indexY': rig.indexY,
      'thumbX': rig.thumbX,
      'thumbY': rig.thumbY,
      ..._poseWeights(
        widget.phase == HandMotionPhase.prepare
            ? eased
            : (elapsed / 0.18).clamp(0.0, 1.0),
      ),
    };
    for (final entry in values.entries) {
      final number = _numbers[entry.key];
      if (number != null && (number.value - entry.value).abs() > 0.0001) {
        number.value = entry.value;
      }
    }
    setState(() {
      _rig = rig;
      _opacity = widget.phase == HandMotionPhase.prepare && previous == null
          ? eased
          : 1;
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
    final origin = _rig?.origin ?? Offset.zero;
    return Positioned(
      left: origin.dx,
      top: origin.dy,
      width: handArtboardSize.width,
      height: handArtboardSize.height,
      child: Opacity(
        opacity: widget.motion == null ? 0 : _opacity,
        child: Transform.flip(
          flipX: widget.hand == AbacusHand.left,
          child: rive.RiveWidget(controller: _rive, fit: rive.Fit.contain),
        ),
      ),
    );
  }
}
