import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

/// Web: `platform/src/trainers/reading/letter-marquee-tap/model.ts`

const minMarqueeTargetCount = 1;
const maxMarqueeTargetCount = 20;

const marqueeTokenWidthPx = 72;
const marqueeTokenGapPx = 28;

const _targetChance = 0.35;

class MarqueeTokenSpec {
  const MarqueeTokenSpec({
    required this.id,
    required this.isTarget,
    required this.letter,
  });

  final String id;
  final bool isTarget;
  final String letter;
}

class MarqueeMotion {
  const MarqueeMotion({
    required this.pixelsPerSecond,
    required this.spawnIntervalMs,
  });

  final double pixelsPerSecond;
  final int spawnIntervalMs;
}

const _speedPresets = {
  'fast': MarqueeMotion(pixelsPerSecond: 240, spawnIntervalMs: 350),
  'medium': MarqueeMotion(pixelsPerSecond: 120, spawnIntervalMs: 700),
  'slow': MarqueeMotion(pixelsPerSecond: 85, spawnIntervalMs: 1000),
};

MarqueeMotion getMarqueeMotion(String speed) {
  return _speedPresets[speed] ?? _speedPresets['medium']!;
}

class BuildMarqueeStreamInput {
  const BuildMarqueeStreamInput({
    required this.practiceLetters,
    required this.seed,
    required this.targetCount,
  });

  final List<String> practiceLetters;
  final int seed;
  final int targetCount;
}

List<MarqueeTokenSpec> buildMarqueeStream(BuildMarqueeStreamInput input) {
  final rng = createSeededRng(input.seed);
  final streamLength = input.targetCount * 12 > 36 ? input.targetCount * 12 : 36;
  final targetSlots = _max(
    input.targetCount * 3,
    (streamLength * _targetChance).round(),
  );
  final targetFlags = _buildTargetFlags(streamLength, targetSlots, rng);
  final distractorPool = russianLettersUpper
      .where((letter) => !input.practiceLetters.contains(letter))
      .toList();

  return [
    for (var index = 0; index < streamLength; index++)
      if (targetFlags[index])
        MarqueeTokenSpec(
          id: 'token-$index',
          isTarget: true,
          letter: normalizeTargetLetter(
            input.practiceLetters[(rng() * input.practiceLetters.length).floor()],
          ),
        )
      else
        MarqueeTokenSpec(
          id: 'token-$index',
          isTarget: false,
          letter: normalizeTargetLetter(
            distractorPool[(rng() * distractorPool.length).floor()],
          ),
        ),
  ];
}

int buildMarqueeStreamSeed(List<Object> parts) {
  return hashParamsSeed([...parts, 'marquee-tap']);
}

String getMarqueeDisplayLetter(String letter, String letterCase) {
  return applyLetterCase(normalizeTargetLetter(letter), letterCase);
}

bool isSuccessfulMarqueeCatch(MarqueeTokenSpec token) {
  return token.isTarget;
}

bool isMarqueeRoundComplete(int caughtCount, int targetCount) {
  return caughtCount >= targetCount;
}

List<bool> _buildTargetFlags(
  int streamLength,
  int targetSlots,
  double Function() rng,
) {
  final flags = List<bool>.generate(
    streamLength,
    (index) => index < targetSlots,
  );

  return _shuffleItems(flags, rng);
}

List<T> _shuffleItems<T>(List<T> items, double Function() rng) {
  final next = [...items];

  for (var index = next.length - 1; index > 0; index--) {
    final swapIndex = (rng() * (index + 1)).floor();
    final temp = next[index];
    next[index] = next[swapIndex];
    next[swapIndex] = temp;
  }

  return next;
}

int _max(int a, int b) => a > b ? a : b;
