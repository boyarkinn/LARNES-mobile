import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Web v2: `platform/src/trainers/mental-arithmetic/flashcard-digit-match/match-hit-test.ts`
class BoardPoint {
  const BoardPoint(this.x, this.y);

  final double x;
  final double y;
}

bool isPointInsideBoardRect(
  BoardPoint point,
  RenderBox target,
  RenderBox board, {
  double padding = 16,
}) {
  final boardOrigin = board.localToGlobal(Offset.zero);
  final targetOrigin = target.localToGlobal(Offset.zero);

  final left = targetOrigin.dx - boardOrigin.dx - padding;
  final right = targetOrigin.dx - boardOrigin.dx + target.size.width + padding;
  final top = targetOrigin.dy - boardOrigin.dy - padding;
  final bottom = targetOrigin.dy - boardOrigin.dy + target.size.height + padding;

  return point.x >= left &&
      point.x <= right &&
      point.y >= top &&
      point.y <= bottom;
}

BoardPoint getElementAnchorPoint(
  RenderBox element,
  RenderBox board, {
  required bool rightSide,
}) {
  final boardOrigin = board.localToGlobal(Offset.zero);
  final elementOrigin = element.localToGlobal(Offset.zero);

  return BoardPoint(
    rightSide
        ? elementOrigin.dx - boardOrigin.dx + element.size.width
        : elementOrigin.dx - boardOrigin.dx,
    elementOrigin.dy - boardOrigin.dy + element.size.height / 2,
  );
}

T? pickTargetAtPoints<T extends Object>({
  required RenderBox board,
  required List<T> elements,
  required RenderBox? Function(T item) getElement,
  required bool Function(T item) isAvailable,
  required List<BoardPoint> points,
  double padding = 16,
}) {
  for (final point in points) {
    T? bestInside;
    var bestArea = double.infinity;

    for (final item in elements) {
      if (!isAvailable(item)) {
        continue;
      }

      final element = getElement(item);
      if (element == null ||
          !isPointInsideBoardRect(point, element, board, padding: padding)) {
        continue;
      }

      final area = element.size.width * element.size.height;
      if (area < bestArea) {
        bestInside = item;
        bestArea = area;
      }
    }

    if (bestInside != null) {
      return bestInside;
    }
  }

  return null;
}

Offset boardPointToOffset(BoardPoint point) => Offset(point.x, point.y);

BoardPoint offsetToBoardPoint(Offset offset) => BoardPoint(offset.dx, offset.dy);
