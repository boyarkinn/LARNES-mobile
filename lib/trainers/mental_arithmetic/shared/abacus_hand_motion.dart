import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

/// Same bead-edge contacts and Rive artboard anchors as the Web hand layer.
const handArtboardSize = Size(280, 300);

enum AbacusHandPose {
  openMiddle,
  fist,
  indexOnly,
  crabSpread,
  crabMiddle,
  crabWorking,
}

class HandContact {
  const HandContact(this.start, this.end);
  final Offset start;
  final Offset end;
}

class AbacusHandMotion {
  const AbacusHandMotion({
    required this.hand,
    required this.pose,
    this.thumb,
    this.index,
  });
  final AbacusHand hand;
  final AbacusHandPose pose;
  final HandContact? thumb;
  final HandContact? index;
}

class HandRig {
  const HandRig({
    required this.origin,
    required this.indexX,
    required this.indexY,
    required this.thumbX,
    required this.thumbY,
  });
  final Offset origin;
  final double indexX;
  final double indexY;
  final double thumbX;
  final double thumbY;
}

class _TipPair {
  const _TipPair(this.index, this.thumb);
  final Offset index;
  final Offset thumb;
}

const _tips = <AbacusHandPose, _TipPair>{
  AbacusHandPose.openMiddle: _TipPair(Offset(24.8, 87.4), Offset(24.8, 151.7)),
  AbacusHandPose.fist: _TipPair(Offset(71.3, 31.3), Offset(30.6, 150.3)),
  AbacusHandPose.indexOnly: _TipPair(Offset(43.4, 79), Offset(31.7, 153.7)),
  AbacusHandPose.crabSpread: _TipPair(Offset(47.9, 59.2), Offset(23.6, 151.9)),
  AbacusHandPose.crabMiddle: _TipPair(Offset(33.6, 93.7), Offset(17.1, 151.7)),
  AbacusHandPose.crabWorking: _TipPair(
    Offset(40.3, 124.7),
    Offset(25.9, 154.6),
  ),
};

HandContact _beadContact(
  AbacusHand hand,
  int rodIndex,
  bool index,
  double startY,
  double endY,
) {
  final side = hand == AbacusHand.right ? 1 : -1;
  final edgeX = rodCenterX(rodIndex) + side * (index ? 8 : -8);
  final beadEdge = endY < startY
      ? AbacusLayout.beadHeight / 2
      : -AbacusLayout.beadHeight / 2;
  return HandContact(
    Offset(edgeX, startY + beadEdge),
    Offset(edgeX, endY + beadEdge),
  );
}

List<AbacusHandMotion> handMotionsForFrame(
  List<RodState> beforeRods,
  PhysicalGestureFrame frame,
) {
  return frame.moves
      .map((move) {
        final before = beforeRods[move.rodIndex];
        final after = move.to;
        final heavenMoved = before.heavenUp != after.heavenUp;
        final earthMoved = before.earthCount != after.earthCount;
        final beforeLayout = layoutRodBeads(before);
        final afterLayout = layoutRodBeads(after);
        HandContact? index;
        HandContact? thumb;
        if (heavenMoved) {
          if (!move.fingers.contains(AbacusFinger.indexFinger)) {
            throw StateError(
              'Небесную косточку должен двигать указательный палец.',
            );
          }
          index = _beadContact(
            move.hand,
            move.rodIndex,
            true,
            beforeLayout.heavenY,
            afterLayout.heavenY,
          );
        }
        if (earthMoved) {
          final thumbMoves =
              heavenMoved ||
              (after.earthCount > before.earthCount &&
                  move.fingers.contains(AbacusFinger.thumb)) ||
              !move.fingers.contains(AbacusFinger.indexFinger);
          final beadIndex = after.earthCount > before.earthCount
              ? after.earthCount - 1
              : after.earthCount;
          final contact = _beadContact(
            move.hand,
            move.rodIndex,
            !thumbMoves,
            beforeLayout.earthYs[beadIndex],
            afterLayout.earthYs[beadIndex],
          );
          if (thumbMoves) {
            thumb = contact;
          } else {
            index = contact;
          }
        }
        if (thumb == null && index == null) {
          throw StateError('Жест не касается косточек.');
        }
        final pose = switch ((heavenMoved, earthMoved)) {
          (false, _) =>
            thumb != null ? AbacusHandPose.fist : AbacusHandPose.indexOnly,
          (_, false) => AbacusHandPose.indexOnly,
          (_, true) => _pairPose(
            index!,
            thumb!,
            before,
            after,
            beforeLayout,
            afterLayout,
          ),
        };
        return AbacusHandMotion(
          hand: move.hand,
          pose: pose,
          thumb: thumb,
          index: index,
        );
      })
      .toList(growable: false);
}

AbacusHandPose _pairPose(
  HandContact index,
  HandContact thumb,
  RodState before,
  RodState after,
  RodBeadLayout beforeLayout,
  RodBeadLayout afterLayout,
) {
  final heavenDelta = afterLayout.heavenY - beforeLayout.heavenY;
  final earthDelta = thumb.end.dy - thumb.start.dy;
  if (heavenDelta.sign == earthDelta.sign) return AbacusHandPose.openMiddle;
  if (after.earthCount < before.earthCount && after.heavenUp) {
    return AbacusHandPose.crabWorking;
  }
  final gaps = [
    (thumb.start.dy - index.start.dy).abs(),
    (thumb.end.dy - index.end.dy).abs(),
  ];
  double score(AbacusHandPose pose) {
    final tips = _tips[pose]!;
    final baseGap = (tips.thumb.dy - tips.index.dy).abs();
    return gaps.map((gap) => (gap - baseGap).abs()).reduce(math.max);
  }

  return score(AbacusHandPose.crabMiddle) <= score(AbacusHandPose.crabSpread)
      ? AbacusHandPose.crabMiddle
      : AbacusHandPose.crabSpread;
}

Offset _origin(AbacusHandMotion motion, bool end, _TipPair tips) {
  final points = <Offset>[];
  for (final (contact, tip) in [
    (motion.thumb, tips.thumb),
    (motion.index, tips.index),
  ]) {
    if (contact == null) continue;
    final worldTip = Offset(
      motion.hand == AbacusHand.right
          ? tip.dx
          : handArtboardSize.width - tip.dx,
      tip.dy,
    );
    points.add((end ? contact.end : contact.start) - worldTip);
  }
  return Offset(
    points.map((point) => point.dx).reduce((a, b) => a + b) / points.length,
    points.map((point) => point.dy).reduce((a, b) => a + b) / points.length,
  );
}

HandRig handRigAt(AbacusHandMotion motion, double progress) {
  final tips = _tips[motion.pose]!;
  final origin = Offset.lerp(
    _origin(motion, false, tips),
    _origin(motion, true, tips),
    progress,
  )!;
  final range = motion.pose == AbacusHandPose.crabWorking
      ? const Offset(10, 14)
      : const Offset(15, 20);
  Offset joystick(HandContact? contact, Offset tip) {
    if (contact == null) return Offset.zero;
    final target = Offset.lerp(contact.start, contact.end, progress)!;
    final tipX = motion.hand == AbacusHand.right
        ? tip.dx
        : handArtboardSize.width - tip.dx;
    final localX = motion.hand == AbacusHand.right
        ? target.dx - origin.dx - tipX
        : -(target.dx - origin.dx - tipX);
    return Offset(
      (localX / range.dx).clamp(-1.0, 1.0),
      ((target.dy - origin.dy - tip.dy) / range.dy).clamp(-1.0, 1.0),
    );
  }

  final index = joystick(motion.index, tips.index);
  final thumb = joystick(motion.thumb, tips.thumb);
  return HandRig(
    origin: origin,
    indexX: index.dx,
    indexY: index.dy,
    thumbX: thumb.dx,
    thumbY: thumb.dy,
  );
}
