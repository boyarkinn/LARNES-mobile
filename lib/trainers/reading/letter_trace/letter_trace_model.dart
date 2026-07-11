import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_trace_model.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_feedback.dart';
import 'package:larnes_mobile/trainers/reading/letter_guides.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';

/// Web: `platform/src/trainers/reading/letter-trace/model.ts`

const letterTraceViewboxSize = 100;
const passSimilarityPercent = tracePassPercent;

TraceScore scoreLetterTrace(String letter, List<TraceStroke> strokes) {
  final reference = getLetterGuidePoints(normalizeTargetLetter(letter));
  final drawn = flattenStrokes(strokes);
  final strokeLength = getStrokeLength(strokes);

  if (drawn.length < 2 ||
      strokeLength < minScoreStrokeLength ||
      reference.length < 2) {
    return TraceScore(
      hasEnoughInk: false,
      similarityPercent: null,
      strokeLength: strokeLength,
    );
  }

  final referenceSamples = resamplePolyline(reference, referenceSampleCount);

  return TraceScore(
    hasEnoughInk: true,
    similarityPercent: corridorCoveragePercent(referenceSamples, strokes),
    strokeLength: strokeLength,
  );
}
