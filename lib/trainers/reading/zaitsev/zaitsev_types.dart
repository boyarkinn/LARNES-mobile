/// Web: `platform/src/trainers/reading/letter-draw-show/zaitsev-catalog/types.ts`

class ZaitsevLetterStroke {
  const ZaitsevLetterStroke({
    required this.path,
    required this.durationMs,
  });

  final String path;
  final int durationMs;
}

class ZaitsevLetterDrawing {
  const ZaitsevLetterDrawing({
    required this.viewBox,
    required this.strokeWidth,
    required this.strokes,
  });

  final String viewBox;
  final double strokeWidth;
  final List<ZaitsevLetterStroke> strokes;
}
