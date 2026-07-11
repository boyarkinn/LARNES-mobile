import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

/// Web v2: `platform/src/trainers/mental-arithmetic/abacus-show/geometry.ts`
abstract final class AbacusLayout {
  static const barHeight = 5.0;
  static const beadHalfWidth = 12.0;
  static const beadHeight = 16.0;
  static const beadSlantRatio = 0.55;
  static const beadStrokeWidth = 0.625;
  static const beamY = 50.0;
  static const earthBeamGap = 4.0;
  static const earthGap = 18.0;
  static const earthTravel = 28.0;
  static const heavenDownY = 42.0;
  static const heavenUpY = 21.0;
  static const rodStrokeWidth = 2.0;
  static const rodTopY = 13.0;
  static const rodWidth = 28.0;
  static const sideInset = 4.0;
  static const verticalPadding = 8.0;
}

class RodBeadLayout {
  const RodBeadLayout({
    required this.heavenY,
    required this.earthYs,
  });

  final double heavenY;
  final List<double> earthYs;
}

class AbacusViewBoxMetrics {
  const AbacusViewBoxMetrics({
    required this.width,
    required this.height,
    required this.beamY,
    required this.topBarY,
    required this.bottomBarY,
  });

  final double width;
  final double height;
  final double beamY;
  final double topBarY;
  final double bottomBarY;
}

double _earthActiveStartY() {
  return AbacusLayout.beamY +
      AbacusLayout.barHeight +
      AbacusLayout.beadHeight / 2 +
      AbacusLayout.earthBeamGap;
}

double _earthBottomCenter() {
  return _earthActiveStartY() + AbacusLayout.earthTravel + AbacusLayout.earthGap * 3;
}

RodBeadLayout layoutRodBeads(RodState state) {
  final activeStartY = _earthActiveStartY();
  final bottomCenter = _earthBottomCenter();

  final earthYs = List<double>.generate(4, (index) {
    if (index < state.earthCount) {
      return activeStartY + index * AbacusLayout.earthGap;
    }

    final inactiveCount = 4 - state.earthCount;
    final slotFromBottom = index - state.earthCount;

    return bottomCenter - (inactiveCount - 1 - slotFromBottom) * AbacusLayout.earthGap;
  });

  return RodBeadLayout(
    heavenY: state.heavenUp ? AbacusLayout.heavenDownY : AbacusLayout.heavenUpY,
    earthYs: earthYs,
  );
}

AbacusViewBoxMetrics abacusViewBox(int totalRods) {
  final bottomBarY =
      _earthBottomCenter() + AbacusLayout.beadHeight / 2 + AbacusLayout.barHeight / 2 + 2;
  final height = bottomBarY + AbacusLayout.barHeight + AbacusLayout.verticalPadding;
  final width = AbacusLayout.sideInset * 2 +
      totalRods * AbacusLayout.rodWidth +
      (totalRods - 1) * 2;

  return AbacusViewBoxMetrics(
    width: width,
    height: height,
    beamY: AbacusLayout.beamY,
    topBarY: AbacusLayout.verticalPadding,
    bottomBarY: bottomBarY,
  );
}

double rodCenterX(int rodIndex) {
  return AbacusLayout.sideInset +
      rodIndex * (AbacusLayout.rodWidth + 2) +
      AbacusLayout.rodWidth / 2;
}

double rodBottomY(double bottomBarY) {
  return bottomBarY + AbacusLayout.barHeight / 2;
}

List<RodBeadLayout> layoutsForRods(List<RodState> rods) {
  return rods.map(layoutRodBeads).toList();
}

RodBeadLayout lerpRodBeadLayout(RodBeadLayout from, RodBeadLayout to, double t) {
  return RodBeadLayout(
    heavenY: _lerp(from.heavenY, to.heavenY, t),
    earthYs: List<double>.generate(
      4,
      (index) => _lerp(from.earthYs[index], to.earthYs[index], t),
    ),
  );
}

double _lerp(double from, double to, double t) => from + (to - from) * t;

List<RodBeadLayout> lerpRodLayouts(
  List<RodBeadLayout> from,
  List<RodBeadLayout> to,
  double t,
) {
  return List.generate(
    from.length,
    (index) => lerpRodBeadLayout(from[index], to[index], t),
  );
}
