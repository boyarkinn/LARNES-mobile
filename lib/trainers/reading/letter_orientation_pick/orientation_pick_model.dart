import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

/// Web: `platform/src/trainers/reading/letter-orientation-pick/model.ts`

const minOptionCount = 4;
const maxOptionCount = 6;

const baseWrongRotationAngles = [45, 90, 135, 180, 225, 270, 315];

const _symmetric180Letters = {'Х', 'Т', 'М', 'Ш', 'Ъ', 'Ы', 'З'};

class OrientationOption {
  const OrientationOption({
    required this.id,
    required this.isUpright,
    required this.letter,
    required this.rotationDeg,
  });

  final String id;
  final bool isUpright;
  final String letter;
  final int rotationDeg;
}

class BuildOrientationOptionsInput {
  const BuildOrientationOptionsInput({
    required this.letter,
    required this.letterCase,
    required this.optionCount,
    required this.rng,
  });

  final String letter;
  final String letterCase;
  final int optionCount;
  final double Function() rng;
}

List<int> getWrongRotationPool(String letter) {
  final normalized = normalizeTargetLetter(letter);

  if (_symmetric180Letters.contains(normalized)) {
    return baseWrongRotationAngles.where((angle) => angle != 180).toList();
  }

  return [...baseWrongRotationAngles];
}

List<OrientationOption> buildOrientationOptions(BuildOrientationOptionsInput input) {
  final displayLetter =
      applyLetterCase(normalizeTargetLetter(input.letter), input.letterCase);
  final wrongPool = getWrongRotationPool(input.letter);
  final wrongCount = input.optionCount - 1 > 0 ? input.optionCount - 1 : 1;
  final shuffledPool = _shuffleItems([...wrongPool], input.rng);
  final wrongRotations = <int>[];

  for (var index = 0; index < wrongCount; index++) {
    wrongRotations.add(shuffledPool[index % shuffledPool.length]);
  }

  final options = <OrientationOption>[
    OrientationOption(
      id: 'upright-0',
      isUpright: true,
      letter: displayLetter,
      rotationDeg: 0,
    ),
    for (var index = 0; index < wrongRotations.length; index++)
      OrientationOption(
        id: 'rot-$index-${wrongRotations[index]}',
        isUpright: false,
        letter: displayLetter,
        rotationDeg: wrongRotations[index],
      ),
  ];

  return _shuffleItems(options, input.rng);
}

bool isUprightOptionSelected(
  String? selectedId,
  List<OrientationOption> options,
) {
  for (final option in options) {
    if (option.id == selectedId) {
      return option.isUpright;
    }
  }

  return false;
}

int buildOrientationPickRoundSeed(List<Object> parts) {
  return hashParamsSeed([...parts, 'letter-orientation-pick']);
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
