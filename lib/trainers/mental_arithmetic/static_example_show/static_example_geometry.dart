import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/move_hints.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

/// Web v2: `static-example-show/geometry.ts` — move overlay layout + extended viewBox.

class MoveOverlayLayout {
  const MoveOverlayLayout({
    required this.arrowDirection,
    required this.arrowX,
    required this.height,
    required this.polarity,
    required this.width,
    required this.x,
    required this.y,
  });

  final String arrowDirection;
  final double arrowX;
  final double height;
  final String polarity;
  final double width;
  final double x;
  final double y;
}

class StaticAbacusViewBoxMetrics {
  const StaticAbacusViewBoxMetrics({
    required this.base,
    required this.viewBoxWidth,
    this.viewBoxX = 0,
  });

  final AbacusViewBoxMetrics base;
  final double viewBoxX;
  final double viewBoxWidth;
}

const _moveOverlayGutter = 16.0;

String _moveOverlayZone(String kind) {
  return kind.startsWith('heaven') ? 'heaven' : 'earth';
}

String _moveOverlayPolarity(String kind) {
  return kind.endsWith('to-bar') ? 'add' : 'subtract';
}

String _moveOverlayArrowDirection(String kind) {
  if (kind == MoveOverlayKind.earthToBar || kind == MoveOverlayKind.heavenFromBar) {
    return 'up';
  }

  return 'down';
}

String _moveOverlayArrowSide(int rodIndex, int totalRods) {
  if (totalRods == 1) {
    return 'left';
  }

  return rodIndex == 0 ? 'left' : 'right';
}

({double fromY, double toY}) _earthBeadTravelEndpoints({
  required String kind,
  required int slotIndex,
  required RodState state,
}) {
  final activeStartY = _earthActiveStartY();

  if (kind == MoveOverlayKind.earthFromBar) {
    final activeSlot = (state.earthCount - 1 - slotIndex).clamp(0, 3);
    final fromY = activeStartY + activeSlot * AbacusLayout.earthGap;

    return (fromY: fromY, toY: fromY + AbacusLayout.earthTravel);
  }

  final targetSlot = (state.earthCount + slotIndex).clamp(0, 3);
  final toY = activeStartY + targetSlot * AbacusLayout.earthGap;

  return (fromY: toY + AbacusLayout.earthTravel, toY: toY);
}

({double fromY, double toY}) _heavenBeadTravelEndpoints(String kind) {
  if (kind == MoveOverlayKind.heavenToBar) {
    return (
      fromY: AbacusLayout.heavenUpY,
      toY: AbacusLayout.heavenDownY,
    );
  }

  return (
    fromY: AbacusLayout.heavenDownY,
    toY: AbacusLayout.heavenUpY,
  );
}

({double fromY, double toY}) _moveOverlayEndpoints({
  required String kind,
  required int slotIndex,
  required RodState state,
}) {
  if (kind == MoveOverlayKind.earthToBar || kind == MoveOverlayKind.earthFromBar) {
    return _earthBeadTravelEndpoints(kind: kind, slotIndex: slotIndex, state: state);
  }

  return _heavenBeadTravelEndpoints(kind);
}

({double arrowX, double width, double x}) _moveOverlayHorizontalFrame({
  required String arrowSide,
  required double cx,
}) {
  final beadLaneWidth = AbacusLayout.beadHalfWidth * 2 + 4;
  final width = beadLaneWidth + _moveOverlayGutter;

  if (arrowSide == 'left') {
    return (
      arrowX: _moveOverlayGutter / 2,
      width: width,
      x: cx - beadLaneWidth / 2 - _moveOverlayGutter,
    );
  }

  return (
    arrowX: beadLaneWidth + _moveOverlayGutter / 2,
    width: width,
    x: cx - beadLaneWidth / 2,
  );
}

MoveOverlayLayout _travelZoneRect({
  required String arrowDirection,
  required String arrowSide,
  required double cx,
  required double fromY,
  required String polarity,
  required double toY,
}) {
  final halfBead = AbacusLayout.beadHeight / 2;
  const padding = 2.0;
  final topY = (fromY < toY ? fromY : toY) - halfBead - padding;
  final bottomY = (fromY > toY ? fromY : toY) + halfBead + padding;
  final frame = _moveOverlayHorizontalFrame(arrowSide: arrowSide, cx: cx);

  return MoveOverlayLayout(
    arrowDirection: arrowDirection,
    arrowX: frame.arrowX,
    height: bottomY - topY,
    polarity: polarity,
    width: frame.width,
    x: frame.x,
    y: topY,
  );
}

MoveOverlayLayout _layoutMergedMoveOverlayGroup({
  required List<MoveOverlay> overlays,
  required List<RodState> rods,
  required int totalRods,
}) {
  final rodIndex = overlays.first.rodIndex;
  final kind = overlays.first.kind;
  final cx = rodCenterX(rodIndex);
  final arrowSide = _moveOverlayArrowSide(rodIndex, totalRods);
  final slotCounters = <String, int>{};

  var minEndpointY = double.infinity;
  var maxEndpointY = double.negativeInfinity;

  for (final overlay in overlays) {
    final counterKey = '${overlay.rodIndex}:${overlay.kind}';
    final slotIndex = slotCounters[counterKey] ?? 0;
    slotCounters[counterKey] = slotIndex + 1;

    final endpoints = _moveOverlayEndpoints(
      kind: overlay.kind,
      slotIndex: slotIndex,
      state: rods[overlay.rodIndex],
    );

    minEndpointY = [
      minEndpointY,
      endpoints.fromY,
      endpoints.toY,
    ].reduce((a, b) => a < b ? a : b);
    maxEndpointY = [
      maxEndpointY,
      endpoints.fromY,
      endpoints.toY,
    ].reduce((a, b) => a > b ? a : b);
  }

  return _travelZoneRect(
    arrowDirection: _moveOverlayArrowDirection(kind),
    arrowSide: arrowSide,
    cx: cx,
    fromY: minEndpointY,
    polarity: _moveOverlayPolarity(kind),
    toY: maxEndpointY,
  );
}

MoveOverlayLayout layoutMoveOverlay({
  required String kind,
  required int rodIndex,
  required int slotIndex,
  required RodState state,
  required int totalRods,
}) {
  final cx = rodCenterX(rodIndex);
  final arrowSide = _moveOverlayArrowSide(rodIndex, totalRods);
  final endpoints = _moveOverlayEndpoints(
    kind: kind,
    slotIndex: slotIndex,
    state: state,
  );

  return _travelZoneRect(
    arrowDirection: _moveOverlayArrowDirection(kind),
    arrowSide: arrowSide,
    cx: cx,
    fromY: endpoints.fromY < endpoints.toY ? endpoints.fromY : endpoints.toY,
    polarity: _moveOverlayPolarity(kind),
    toY: endpoints.fromY > endpoints.toY ? endpoints.fromY : endpoints.toY,
  );
}

List<MoveOverlayLayout> layoutMoveOverlays(
  List<MoveOverlay> moveOverlays,
  List<RodState> rods,
  int totalRods,
) {
  final groups = <String, List<MoveOverlay>>{};

  for (final overlay in moveOverlays) {
    final key =
        '${overlay.rodIndex}:${_moveOverlayZone(overlay.kind)}:${_moveOverlayPolarity(overlay.kind)}';
    groups.putIfAbsent(key, () => []).add(overlay);
  }

  return groups.values
      .map(
        (overlays) => _layoutMergedMoveOverlayGroup(
          overlays: overlays,
          rods: rods,
          totalRods: totalRods,
        ),
      )
      .toList();
}

({double left, double right}) moveOverlayViewBoxPadding(
  List<MoveOverlayLayout> layouts,
  double baseWidth,
) {
  var left = 0.0;
  var right = 0.0;

  for (final layout in layouts) {
    if (layout.x < 0) {
      left = left > -layout.x + 1 ? left : -layout.x + 1;
    }

    final layoutRight = layout.x + layout.width;

    if (layoutRight > baseWidth) {
      right = right > layoutRight - baseWidth + 1 ? right : layoutRight - baseWidth + 1;
    }
  }

  return (left: left, right: right);
}

StaticAbacusViewBoxMetrics abacusViewBoxWithMoveOverlays(
  int totalRods,
  List<MoveOverlay> moveOverlays,
  List<RodState> rods,
) {
  final base = abacusViewBox(totalRods);

  if (moveOverlays.isEmpty) {
    return StaticAbacusViewBoxMetrics(
      base: base,
      viewBoxWidth: base.width,
    );
  }

  final layouts = layoutMoveOverlays(moveOverlays, rods, totalRods);
  final padding = moveOverlayViewBoxPadding(layouts, base.width);

  return StaticAbacusViewBoxMetrics(
    base: base,
    viewBoxWidth: base.width + padding.left + padding.right,
    viewBoxX: -padding.left,
  );
}

double _earthActiveStartY() {
  return AbacusLayout.beamY +
      AbacusLayout.barHeight +
      AbacusLayout.beadHeight / 2 +
      AbacusLayout.earthBeamGap;
}
