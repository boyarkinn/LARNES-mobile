import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/match_connection/connection_path.dart';

/// Web: `platform/src/trainers/shared/match-connection/match-connection-lines.tsx`
class MatchConnectionLineSegment {
  const MatchConnectionLineSegment({
    required this.from,
    required this.stroke,
    required this.to,
    this.path,
  });

  final Offset from;
  final Color stroke;
  final Offset to;
  final Path? path;
}

class MatchConnectionDraftSegment {
  const MatchConnectionDraftSegment({
    required this.from,
    required this.stroke,
    required this.to,
  });

  final Offset from;
  final Color stroke;
  final Offset to;
}

class MatchConnectionWrongSegment {
  const MatchConnectionWrongSegment({required this.from, required this.to});

  final Offset from;
  final Offset to;
}

const matchConnectionWrongFlashMs = 450;
const matchConnectionWrongStroke = Color(0xFFF87171);

class MatchConnectionCircle {
  const MatchConnectionCircle({required this.center, required this.radius});
  final Offset center;
  final double radius;
}

class MatchConnectionLinesPainter extends CustomPainter {
  MatchConnectionLinesPainter({
    required this.draft,
    required this.lockedLines,
    required this.wrong,
    this.circleCutouts = const [],
    this.wrongStroke = matchConnectionWrongStroke,
  });

  final MatchConnectionDraftSegment? draft;
  final List<MatchConnectionLineSegment> lockedLines;
  final MatchConnectionWrongSegment? wrong;
  final List<MatchConnectionCircle> circleCutouts;
  final Color wrongStroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (circleCutouts.isNotEmpty) {
      final clip = Path()..addRect(Offset.zero & size);
      for (final circle in circleCutouts) {
        clip.addOval(Rect.fromCircle(center: circle.center, radius: circle.radius));
      }
      clip.fillType = PathFillType.evenOdd;
      canvas.clipPath(clip);
    }
    for (final line in lockedLines) {
      canvas.drawPath(
        line.path ?? buildConnectionPath(line.from, line.to),
        Paint()
          ..color = line.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    if (draft != null) {
      drawDashedConnectionPath(
        canvas,
        buildConnectionPath(draft!.from, draft!.to),
        Paint()
          ..color = draft!.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    if (wrong != null) {
      canvas.drawPath(
        buildConnectionPath(wrong!.from, wrong!.to),
        Paint()
          ..color = wrongStroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MatchConnectionLinesPainter oldDelegate) {
    return oldDelegate.draft != draft ||
        oldDelegate.circleCutouts != circleCutouts ||
        oldDelegate.lockedLines != lockedLines ||
        oldDelegate.wrong != wrong ||
        oldDelegate.wrongStroke != wrongStroke;
  }
}
