import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

/// Web v2: `platform/src/trainers/mental-arithmetic/abacus-show/geometry.ts`
abstract final class AbacusLayout {
  static const barHeight = 5.0;
  static const beadHalfWidth = 13.2;
  static const beadHeight = 17.0;
  static const beadSlantRatio = 0.44;
  static const beadStrokeWidth = 0.625;
  static const beamY = 50.0;
  /// 0 — поднятая earth-косточка вплотную к нижнему краю средней планки.
  static const earthBeamGap = 0.0;
  /// Шаг стопки = высота косточки — без зазоров между соседними earth-бусинами.
  static const earthGap = beadHeight;
  /// Подъём earth-косточки: earthBeamGap + earthTravel = высота одной косточки.
  static const earthTravel = beadHeight - earthBeamGap;
  /// Активная heaven-косточка: нижний край = верх средней планки.
  static const heavenDownY = beamY - beadHeight / 2;
  /// Неактивная heaven-косточка: зона снизу = одна косточка до планки.
  static const heavenUpY = heavenDownY - beadHeight;
  static const rodStrokeWidth = 2.0;
  static const rodEdgeOffset = 0.85;
  static const rodEdgeStrokeWidth = 0.85;
  static const rodGap = 2.2;
  static const rodWidth = 30.8;
  static const sideInset = 4.4;
  static const verticalPadding = 8.0;

  static double get heavenInactiveTopEdge => heavenUpY - beadHeight / 2;

  static double get layoutTopBarY => heavenInactiveTopEdge - barHeight;

  static double get rodTopY => heavenInactiveTopEdge;
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
      _earthBottomCenter() + AbacusLayout.beadHeight / 2;
  final height = bottomBarY + AbacusLayout.barHeight + AbacusLayout.verticalPadding;
  final width = AbacusLayout.sideInset * 2 +
      totalRods * AbacusLayout.rodWidth +
      (totalRods - 1) * AbacusLayout.rodGap;

  return AbacusViewBoxMetrics(
    width: width,
    height: height,
    beamY: AbacusLayout.beamY,
    topBarY: AbacusLayout.layoutTopBarY,
    bottomBarY: bottomBarY,
  );
}

double rodCenterX(int rodIndex) {
  return AbacusLayout.sideInset +
      rodIndex * (AbacusLayout.rodWidth + AbacusLayout.rodGap) +
      AbacusLayout.rodWidth / 2;
}

double rodBottomY(double bottomBarY) {
  return bottomBarY + AbacusLayout.barHeight / 2;
}

/// Красная метка: верхняя earth-косточка каждого 3-го разряда справа (ед., дес., | сот., …).
bool isMarkedEarthBead(int rodIndex, int earthBeadIndex, int totalRods) {
  if (earthBeadIndex != 0) {
    return false;
  }

  final rodFromRight = totalRods - 1 - rodIndex;

  return (rodFromRight + 1) % 3 == 0;
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
