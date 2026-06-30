import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

class AbacusLayout {
  const AbacusLayout._();

  static const beadHalfWidth = 9.0;
  static const beadHeight = 11.0;
  static const beamHeight = 6.0;
  static const beamY = 52.0;
  static const earthGap = 13.0;
  static const earthInactiveBottomY = 118.0;
  static const frameRadius = 10.0;
  static const frameStroke = 3.0;
  static const heavenDownY = 44.0;
  static const heavenUpY = 16.0;
  static const rodTopY = 8.0;
  static const rodWidth = 26.0;
  static const topPadding = 12.0;
  static const unitDotRadius = 2.5;
  static const verticalPadding = 14.0;
}

class RodBeadLayout {
  const RodBeadLayout({
    required this.heavenY,
    required this.earthYs,
  });

  final double heavenY;
  final List<double> earthYs;
}

RodBeadLayout layoutRodBeads(RodState state) {
  final earthActiveStartY = AbacusLayout.beamY + AbacusLayout.beamHeight / 2 + 4;
  final inactiveYs = [
    AbacusLayout.earthInactiveBottomY - AbacusLayout.earthGap * 3,
    AbacusLayout.earthInactiveBottomY - AbacusLayout.earthGap * 2,
    AbacusLayout.earthInactiveBottomY - AbacusLayout.earthGap,
    AbacusLayout.earthInactiveBottomY,
  ];

  final earthYs = List<double>.generate(4, (index) {
    if (index < state.earthCount) {
      return earthActiveStartY + index * AbacusLayout.earthGap;
    }
    return inactiveYs[index];
  });

  return RodBeadLayout(
    heavenY: state.heavenUp ? AbacusLayout.heavenDownY : AbacusLayout.heavenUpY,
    earthYs: earthYs,
  );
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

({double width, double height}) abacusViewBox(int totalRods) {
  final width = AbacusLayout.verticalPadding * 2 +
      totalRods * AbacusLayout.rodWidth +
      (totalRods - 1) * 2;
  final height = AbacusLayout.topPadding + 132 + AbacusLayout.verticalPadding;
  return (width: width, height: height);
}

double rodCenterX(int rodIndex) {
  return AbacusLayout.verticalPadding +
      rodIndex * (AbacusLayout.rodWidth + 2) +
      AbacusLayout.rodWidth / 2;
}

bool isUnitMarkerRod(int rodIndex, int totalRods) {
  final placeFromRight = totalRods - 1 - rodIndex;
  return placeFromRight % 3 == 0;
}

List<RodBeadLayout> layoutsForRods(List<RodState> rods) {
  return rods.map(layoutRodBeads).toList();
}

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
