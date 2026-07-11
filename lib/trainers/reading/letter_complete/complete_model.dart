import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_trace_model.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_feedback.dart';
import 'package:larnes_mobile/trainers/reading/letter_guides.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

/// Web: `platform/src/trainers/reading/letter-complete/model.ts`

const minCompletableSegments = 2;
const passSimilarityPercent = tracePassPercent;
const letterCompleteViewboxSize = 100;

int getSegmentCount(String letter) {
  return getLetterGuideSegments(normalizeTargetLetter(letter)).length;
}

bool isCompletableLetter(String letter) {
  return getSegmentCount(letter) >= minCompletableSegments;
}

List<TracePoint> getLetterGuideSegmentPoints(String letter, int segmentIndex) {
  final segments = getLetterGuideSegments(normalizeTargetLetter(letter));

  if (segmentIndex < 0 || segmentIndex >= segments.length) {
    return const [];
  }

  return segments[segmentIndex];
}

bool isValidMissingSegment(String letter, Object missingSegment) {
  final count = getSegmentCount(letter);

  if (count < minCompletableSegments) {
    return false;
  }

  if (missingSegment == 'random') {
    return true;
  }

  final index =
      missingSegment is int ? missingSegment : int.tryParse('$missingSegment');

  return index != null && index >= 0 && index < count;
}

int buildLetterCompleteRoundSeed(List<Object> parts) {
  return hashParamsSeed([...parts, 'letter-complete']);
}

int resolveMissingSegmentIndex(
  String letter,
  Object missingSegment,
  int seed,
) {
  final count = getSegmentCount(letter);

  if (missingSegment != 'random') {
    final index =
        missingSegment is int ? missingSegment : int.tryParse('$missingSegment');

    if (index != null && index >= 0 && index < count) {
      return index;
    }
  }

  final rng = createSeededRng(seed);

  return (rng() * count).floor();
}

TraceScore scoreLetterSegmentTrace(
  String letter,
  int segmentIndex,
  List<TraceStroke> strokes,
) {
  final reference = getLetterGuideSegmentPoints(letter, segmentIndex);
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

bool isSuccessfulComplete(TraceScore score) {
  return score.similarityPercent != null &&
      score.similarityPercent! >= passSimilarityPercent;
}
