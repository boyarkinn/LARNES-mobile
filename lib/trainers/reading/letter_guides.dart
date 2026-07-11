import 'dart:math' as math;

import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';

/// Web: `platform/src/trainers/reading/letter-trace/letter-guides.ts`

List<TracePoint> _line(
  double x1,
  double y1,
  double x2,
  double y2,
  int steps,
) {
  final points = <TracePoint>[];

  for (var index = 0; index <= steps; index++) {
    final t = index / steps;
    points.add(
      TracePoint(
        x: x1 + (x2 - x1) * t,
        y: y1 + (y2 - y1) * t,
      ),
    );
  }

  return points;
}

List<TracePoint> _arc(
  double cx,
  double cy,
  double radius,
  double startAngle,
  double endAngle,
  int steps,
) {
  final points = <TracePoint>[];

  for (var index = 0; index <= steps; index++) {
    final t = index / steps;
    final angle = startAngle + (endAngle - startAngle) * t;
    points.add(
      TracePoint(
        x: cx + radius * math.cos(angle),
        y: cy + radius * math.sin(angle),
      ),
    );
  }

  return points;
}

final _guideA = <List<TracePoint>>[
  _line(0.28, 0.78, 0.5, 0.22, 16),
  _line(0.72, 0.78, 0.5, 0.22, 16),
  _line(0.36, 0.52, 0.64, 0.52, 10),
];

final _guideB = <List<TracePoint>>[
  _line(0.32, 0.22, 0.32, 0.78, 18),
  _arc(0.48, 0.32, 0.16, math.pi, math.pi * 2.05, 12),
  _arc(0.48, 0.62, 0.16, math.pi, math.pi * 2.05, 12),
];

final _guideV = <List<TracePoint>>[
  _line(0.32, 0.22, 0.32, 0.78, 14),
  _arc(0.5, 0.32, 0.16, math.pi * 1.05, math.pi * 2.1, 12),
  _arc(0.5, 0.62, 0.16, math.pi * 1.05, math.pi * 2.1, 12),
];

final _guideG = <List<TracePoint>>[
  _line(0.68, 0.22, 0.32, 0.22, 12),
  _line(0.32, 0.22, 0.32, 0.78, 16),
];

final _guideD = <List<TracePoint>>[
  _arc(0.5, 0.32, 0.22, math.pi * 0.95, math.pi * 2.05, 16),
  _line(0.3, 0.78, 0.7, 0.78, 12),
];

final _guideE = <List<TracePoint>>[
  _line(0.68, 0.22, 0.32, 0.22, 10),
  _line(0.32, 0.22, 0.32, 0.78, 16),
  _line(0.32, 0.5, 0.62, 0.5, 8),
  _line(0.32, 0.78, 0.62, 0.78, 8),
];

final _guideZh = <List<TracePoint>>[
  _line(0.28, 0.24, 0.72, 0.76, 14),
  _line(0.72, 0.24, 0.28, 0.76, 14),
  _line(0.5, 0.22, 0.5, 0.78, 14),
];

final _guideZ = <List<TracePoint>>[
  _arc(0.52, 0.3, 0.18, math.pi * 0.85, math.pi * 2.15, 12),
  _arc(0.52, 0.62, 0.18, math.pi * 1.05, math.pi * 2.35, 12),
];

final _guideI = <List<TracePoint>>[
  _line(0.38, 0.22, 0.38, 0.78, 18),
  _line(0.62, 0.22, 0.62, 0.78, 18),
  _line(0.38, 0.78, 0.62, 0.78, 10),
];

final _guideY = <List<TracePoint>>[
  ..._guideI,
  _arc(0.5, 0.16, 0.12, math.pi, math.pi * 2.05, 10),
];

final _guideK = <List<TracePoint>>[
  _line(0.34, 0.22, 0.34, 0.78, 18),
  _line(0.34, 0.5, 0.68, 0.22, 12),
  _line(0.34, 0.5, 0.68, 0.78, 12),
];

final _guideL = <List<TracePoint>>[
  _line(0.28, 0.78, 0.5, 0.22, 16),
  _line(0.72, 0.78, 0.5, 0.22, 16),
];

final _guideM = <List<TracePoint>>[
  _line(0.26, 0.78, 0.26, 0.22, 14),
  _line(0.26, 0.22, 0.5, 0.52, 10),
  _line(0.5, 0.52, 0.74, 0.22, 10),
  _line(0.74, 0.22, 0.74, 0.78, 14),
];

final _guideN = <List<TracePoint>>[
  _line(0.32, 0.78, 0.32, 0.22, 16),
  _line(0.68, 0.78, 0.68, 0.22, 16),
  _line(0.32, 0.22, 0.68, 0.22, 10),
];

final _guideO = <List<TracePoint>>[
  _arc(0.5, 0.5, 0.24, 0, math.pi * 2, 36),
];

final _guideP = <List<TracePoint>>[
  _line(0.34, 0.22, 0.34, 0.78, 18),
  _arc(0.52, 0.32, 0.18, math.pi, math.pi * 2.05, 14),
  _line(0.34, 0.5, 0.68, 0.5, 10),
];

final _guideR = <List<TracePoint>>[
  _line(0.34, 0.22, 0.34, 0.78, 18),
  _arc(0.52, 0.32, 0.18, math.pi, math.pi * 2.05, 14),
  _line(0.34, 0.5, 0.68, 0.78, 12),
];

final _guideS = <List<TracePoint>>[
  _arc(0.54, 0.5, 0.22, math.pi * 0.55, math.pi * 2.45, 24),
];

final _guideT = <List<TracePoint>>[
  _line(0.28, 0.22, 0.72, 0.22, 12),
  _line(0.5, 0.22, 0.5, 0.78, 18),
];

final _guideU = <List<TracePoint>>[
  _arc(0.5, 0.42, 0.2, math.pi * 0.15, math.pi * 0.85, 14),
  _line(0.68, 0.52, 0.78, 0.78, 8),
];

final _guideF = <List<TracePoint>>[
  _line(0.5, 0.18, 0.5, 0.82, 18),
  _arc(0.5, 0.5, 0.22, math.pi * 0.35, math.pi * 1.65, 20),
];

final _guideH = <List<TracePoint>>[
  _line(0.28, 0.24, 0.72, 0.76, 14),
  _line(0.72, 0.24, 0.28, 0.76, 14),
];

final _guideTs = <List<TracePoint>>[
  _line(0.34, 0.22, 0.34, 0.72, 14),
  _line(0.34, 0.72, 0.58, 0.72, 8),
  _line(0.58, 0.72, 0.58, 0.78, 4),
];

final _guideCh = <List<TracePoint>>[
  _line(0.66, 0.22, 0.66, 0.78, 16),
  _arc(0.48, 0.52, 0.18, math.pi * 0.55, math.pi * 1.45, 14),
];

final _guideSh = <List<TracePoint>>[
  _line(0.28, 0.22, 0.28, 0.72, 12),
  _line(0.5, 0.22, 0.5, 0.72, 12),
  _line(0.72, 0.22, 0.72, 0.72, 12),
  _line(0.28, 0.72, 0.72, 0.72, 10),
];

final _guideShch = <List<TracePoint>>[
  ..._guideSh,
  _line(0.72, 0.72, 0.82, 0.78, 4),
];

final _guideHard = <List<TracePoint>>[
  _line(0.34, 0.42, 0.34, 0.78, 10),
  _arc(0.5, 0.32, 0.16, math.pi * 0.85, math.pi * 2.15, 12),
  _line(0.62, 0.22, 0.72, 0.22, 4),
];

final _guideYeri = <List<TracePoint>>[
  _line(0.28, 0.22, 0.28, 0.78, 14),
  _arc(0.42, 0.32, 0.12, math.pi * 0.85, math.pi * 2.15, 10),
  _line(0.58, 0.22, 0.58, 0.78, 14),
];

final _guideSoft = <List<TracePoint>>[
  _line(0.38, 0.42, 0.38, 0.78, 10),
  _arc(0.52, 0.32, 0.14, math.pi * 0.85, math.pi * 2.15, 10),
];

final _guideEo = <List<TracePoint>>[
  _arc(0.54, 0.5, 0.22, math.pi * 0.35, math.pi * 1.85, 20),
  _line(0.42, 0.5, 0.66, 0.5, 8),
];

final _guideYu = <List<TracePoint>>[
  _arc(0.38, 0.5, 0.14, math.pi * 0.35, math.pi * 1.85, 12),
  _line(0.58, 0.22, 0.58, 0.78, 14),
  _line(0.58, 0.78, 0.72, 0.78, 6),
];

final _guideYa = <List<TracePoint>>[
  _line(0.66, 0.22, 0.34, 0.52, 12),
  _arc(0.48, 0.62, 0.16, math.pi * 0.35, math.pi * 1.65, 12),
  _line(0.34, 0.52, 0.66, 0.78, 10),
];

final Map<String, List<List<TracePoint>>> letterGuideSegments = {
  'А': _guideA,
  'Б': _guideB,
  'В': _guideV,
  'Г': _guideG,
  'Д': _guideD,
  'Е': _guideE,
  'Ж': _guideZh,
  'З': _guideZ,
  'И': _guideI,
  'Й': _guideY,
  'К': _guideK,
  'Л': _guideL,
  'М': _guideM,
  'Н': _guideN,
  'О': _guideO,
  'П': _guideP,
  'Р': _guideR,
  'С': _guideS,
  'Т': _guideT,
  'У': _guideU,
  'Ф': _guideF,
  'Х': _guideH,
  'Ц': _guideTs,
  'Ч': _guideCh,
  'Ш': _guideSh,
  'Щ': _guideShch,
  'Ъ': _guideHard,
  'Ы': _guideYeri,
  'Ь': _guideSoft,
  'Э': _guideEo,
  'Ю': _guideYu,
  'Я': _guideYa,
};

void _assertLetterGuidesComplete() {
  for (final letter in russianLettersUpper) {
    if (!letterGuideSegments.containsKey(letter)) {
      throw StateError('Missing letter guide for $letter');
    }
  }
}

final _letterGuidesReady = (() {
  _assertLetterGuidesComplete();
  return true;
})();

bool get letterGuidesReady => _letterGuidesReady;

List<List<TracePoint>> getLetterGuideSegments(String letter) {
  return letterGuideSegments[letter] ?? _guideO;
}

List<TracePoint> getLetterGuidePoints(String letter) {
  return getLetterGuideSegments(letter).expand((segment) => segment).toList();
}
