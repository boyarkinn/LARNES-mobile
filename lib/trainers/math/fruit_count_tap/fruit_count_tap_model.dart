import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

typedef FruitSlug = String;

const fruitLabels = <String, String>{
  'apple': 'яблок',
  'banana': 'бананов',
  'cherry': 'вишен',
  'grape': 'виноградин',
  'orange': 'апельсинов',
  'peach': 'персиков',
  'pear': 'груш',
  'plum': 'слив',
  'strawberry': 'клубник',
  'watermelon': 'арбузов',
};

class FruitToken {
  const FruitToken({
    required this.fruit,
    required this.id,
    required this.isTarget,
  });

  final FruitSlug fruit;
  final String id;
  final bool isTarget;
}

class BuildFruitFieldInput {
  const BuildFruitFieldInput({
    required this.answerRangeStart,
    required this.fruitTypeCount,
    required this.rng,
    required this.targetCount,
    required this.targetFruit,
    required this.totalFruits,
  });

  final int answerRangeStart;
  final int fruitTypeCount;
  final double Function() rng;
  final int targetCount;
  final FruitSlug targetFruit;
  final int totalFruits;
}

bool isFruitSlug(String value) => fruitSlugs.contains(value);

String normalizeFruitSlug(String value) {
  return isFruitSlug(value) ? value : 'watermelon';
}

List<int> getAnswerChoices(int answerRangeStart) {
  return List.generate(4, (offset) => answerRangeStart + offset);
}

bool canFitFruitField(
  int targetCount,
  int fruitTypeCount,
  int totalFruits,
) {
  return totalFruits >= targetCount &&
      totalFruits >= fruitTypeCount &&
      totalFruits <= maxFruitFieldTokens &&
      fruitTypeCount >= 1 &&
      fruitTypeCount <= fruitSlugs.length &&
      totalFruits >= targetCount + (fruitTypeCount - 1 > 0 ? fruitTypeCount - 1 : 0);
}

List<FruitToken> buildFruitTokens(BuildFruitFieldInput input) {
  final distractorFruits = _pickDistractorFruits(
    input.targetFruit,
    input.fruitTypeCount,
    input.rng,
  );
  final tokens = <FruitToken>[];

  for (var index = 0; index < input.targetCount; index++) {
    tokens.add(
      FruitToken(
        fruit: input.targetFruit,
        id: 'target-$index',
        isTarget: true,
      ),
    );
  }

  final remaining = input.totalFruits - input.targetCount;
  final counts = _distributeCounts(remaining, distractorFruits.length, input.rng);

  for (var typeIndex = 0; typeIndex < distractorFruits.length; typeIndex++) {
    final fruit = distractorFruits[typeIndex];
    for (var index = 0; index < counts[typeIndex]; index++) {
      tokens.add(
        FruitToken(
          fruit: fruit,
          id: '$fruit-$typeIndex-$index',
          isTarget: false,
        ),
      );
    }
  }

  return _shuffleTokens(tokens, input.rng);
}

List<FruitSlug> _pickDistractorFruits(
  FruitSlug targetFruit,
  int fruitTypeCount,
  double Function() rng,
) {
  final pool = fruitSlugs.where((fruit) => fruit != targetFruit).toList();
  final shuffled = _shuffleTokens(pool, rng);
  final count = fruitTypeCount - 1;
  if (count <= 0) {
    return const [];
  }
  return shuffled.take(count).toList();
}

List<int> _distributeCounts(
  int total,
  int bucketCount,
  double Function() rng,
) {
  if (bucketCount == 0) {
    return const [];
  }

  final counts = List<int>.filled(bucketCount, 1);
  var leftover = total - bucketCount;

  while (leftover > 0) {
    final index = (rng() * bucketCount).floor().clamp(0, bucketCount - 1);
    counts[index] += 1;
    leftover -= 1;
  }

  return counts;
}

List<T> _shuffleTokens<T>(List<T> items, double Function() rng) {
  final next = List<T>.from(items);

  for (var index = next.length - 1; index > 0; index--) {
    final swapIndex = (rng() * (index + 1)).floor();
    final temp = next[index];
    next[index] = next[swapIndex];
    next[swapIndex] = temp;
  }

  return next;
}
