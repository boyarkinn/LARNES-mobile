import 'package:larnes_mobile/trainers/reading/zaitsev/zaitsev_catalog.dart';

export 'package:larnes_mobile/trainers/reading/zaitsev/zaitsev_catalog.dart'
    show getZaitsevLetterDrawing, isSupportedDrawShowLetter;

/// Web: `platform/src/trainers/reading/letter-draw-show/model.ts`

const minDrawShowRounds = 1;
const maxDrawShowRounds = 5;
const defaultDrawShowRounds = 1;

const drawShowStrokePauseMs = 280;
const drawShowRoundPauseMs = 900;
const drawShowCompleteDelayMs = 900;

const zaitsevStrokeColors = [
  '#e11d48',
  '#2563eb',
  '#059669',
];

String getStrokeColor(int strokeIndex) {
  return zaitsevStrokeColors[strokeIndex % zaitsevStrokeColors.length];
}

int normalizeDrawShowRounds(int value) {
  return value.clamp(minDrawShowRounds, maxDrawShowRounds).toInt();
}

int estimateDrawingDurationMs(String letter, int rounds) {
  final drawing = getZaitsevLetterDrawing(letter);

  if (drawing == null) {
    return 0;
  }

  final strokeMs = drawing.strokes
      .fold<int>(0, (sum, stroke) => sum + stroke.durationMs);
  final pausesMs =
      (drawing.strokes.length > 1 ? drawing.strokes.length - 1 : 0) *
          drawShowStrokePauseMs;
  final oneRoundMs = strokeMs + pausesMs + drawShowRoundPauseMs;

  return oneRoundMs * normalizeDrawShowRounds(rounds);
}
