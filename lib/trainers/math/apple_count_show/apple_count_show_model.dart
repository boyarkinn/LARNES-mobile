const minAppleCount = 1;
const maxTotalApples = 15;
const maxTargetCount = 9;

const targetDisplayWithDigit = 'with_digit';
const targetDisplayAudioOnly = 'audio_only';

class ScatterPosition {
  const ScatterPosition({required this.xPercent, required this.yPercent});

  final double xPercent;
  final double yPercent;
}

class AppleEntity {
  const AppleEntity({
    required this.id,
    required this.zone,
    required this.xPercent,
    required this.yPercent,
    this.basketSlot,
  });

  final String id;
  final String zone;
  final double xPercent;
  final double yPercent;
  final int? basketSlot;

  static const zoneField = 'field';
  static const zoneBasket = 'basket';

  AppleEntity copyWith({
    String? zone,
    double? xPercent,
    double? yPercent,
    int? basketSlot,
    bool clearBasketSlot = false,
  }) {
    return AppleEntity(
      id: id,
      zone: zone ?? this.zone,
      xPercent: xPercent ?? this.xPercent,
      yPercent: yPercent ?? this.yPercent,
      basketSlot: clearBasketSlot ? null : (basketSlot ?? this.basketSlot),
    );
  }
}

int normalizeTargetCount(Object? value) {
  final parsed = value is num ? value.toInt() : int.tryParse('$value');
  if (parsed == null) {
    return 2;
  }
  return parsed.clamp(minAppleCount, maxTargetCount);
}

int normalizeTotalApples(Object? value) {
  final parsed = value is num ? value.toInt() : int.tryParse('$value');
  if (parsed == null) {
    return 5;
  }
  return parsed.clamp(minAppleCount, maxTotalApples);
}

String normalizeTargetDisplay(Object? value) {
  if (value == targetDisplayAudioOnly) {
    return targetDisplayAudioOnly;
  }
  return targetDisplayWithDigit;
}

bool isValidAppleParams(int totalApples, int targetCount) {
  return totalApples >= targetCount;
}

int _hashParamsSeed(List<Object> parts) {
  var hash = 2166136261;
  for (final part in parts) {
    final text = '$part';
    for (var index = 0; index < text.length; index++) {
      hash ^= text.codeUnitAt(index);
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
  }
  return hash;
}

int buildScatterSeed(
  int totalApples,
  int targetCount,
  String targetDisplay, [
  int shuffleGeneration = 0,
]) {
  return _hashParamsSeed([
    totalApples,
    targetCount,
    targetDisplay,
    shuffleGeneration,
    'apple-count-show',
  ]);
}

List<ScatterPosition> buildScatterPositions(int count, int seed) {
  if (count <= 0) {
    return const [];
  }

  var rngState = seed;
  final positions = <ScatterPosition>[];

  for (var index = 0; index < count; index++) {
    rngState = (rngState * 1664525 + 1013904223) & 0xFFFFFFFF;
    final xRng = rngState / 4294967296;
    rngState = (rngState * 1664525 + 1013904223) & 0xFFFFFFFF;
    final yRng = rngState / 4294967296;
    final above = index.isEven;

    positions.add(
      ScatterPosition(
        xPercent: 8 + xRng * 84,
        yPercent: above ? 6 + yRng * 38 : 52 + yRng * 34,
      ),
    );
  }

  return positions;
}

List<AppleEntity> buildInitialApples(
  int totalApples,
  int targetCount,
  String targetDisplay, [
  int shuffleGeneration = 0,
]) {
  final scatter = buildScatterPositions(
    totalApples,
    buildScatterSeed(totalApples, targetCount, targetDisplay, shuffleGeneration),
  );

  return List.generate(scatter.length, (index) {
    final position = scatter[index];
    return AppleEntity(
      id: 'apple-$index',
      zone: AppleEntity.zoneField,
      xPercent: position.xPercent,
      yPercent: position.yPercent,
    );
  });
}

int countApplesInBasket(List<AppleEntity> apples) {
  return apples.where((apple) => apple.zone == AppleEntity.zoneBasket).length;
}

bool isCorrectBasketCount(int basketCount, int targetCount) {
  return basketCount == normalizeTargetCount(targetCount);
}

List<AppleEntity> moveAppleToBasket(List<AppleEntity> apples, String appleId) {
  final nextSlot = countApplesInBasket(apples);
  return apples
      .map(
        (apple) => apple.id == appleId
            ? apple.copyWith(zone: AppleEntity.zoneBasket, basketSlot: nextSlot)
            : apple,
      )
      .toList();
}

List<AppleEntity> moveAppleToField(
  List<AppleEntity> apples,
  String appleId,
  ScatterPosition position,
) {
  final moved = apples
      .map(
        (apple) => apple.id == appleId
            ? apple.copyWith(
                zone: AppleEntity.zoneField,
                xPercent: position.xPercent,
                yPercent: position.yPercent,
                clearBasketSlot: true,
              )
            : apple,
      )
      .toList();
  return _rebalanceBasketSlots(moved);
}

List<AppleEntity> reshuffleAllApplesToField(
  List<AppleEntity> apples,
  int totalApples,
  int targetCount,
  String targetDisplay,
  int shuffleGeneration,
) {
  final scatter = buildScatterPositions(
    totalApples,
    buildScatterSeed(totalApples, targetCount, targetDisplay, shuffleGeneration),
  );

  return List.generate(apples.length, (index) {
    final apple = apples[index];
    final position = scatter[index];
    return apple.copyWith(
      zone: AppleEntity.zoneField,
      xPercent: position?.xPercent ?? 50,
      yPercent: position?.yPercent ?? 50,
      clearBasketSlot: true,
    );
  });
}

List<AppleEntity> _rebalanceBasketSlots(List<AppleEntity> apples) {
  final basketApples = apples
      .where((apple) => apple.zone == AppleEntity.zoneBasket)
      .toList()
    ..sort((left, right) => (left.basketSlot ?? 0).compareTo(right.basketSlot ?? 0));

  final slotById = <String, int>{};
  for (var index = 0; index < basketApples.length; index++) {
    slotById[basketApples[index].id] = index;
  }

  return apples
      .map(
        (apple) => apple.zone == AppleEntity.zoneBasket
            ? apple.copyWith(basketSlot: slotById[apple.id])
            : apple,
      )
      .toList();
}

@Deprecated('Use normalizeTargetCount')
int normalizeDigit(num digit) {
  return normalizeTargetCount(digit);
}

@Deprecated('Use normalizeTargetCount')
int digitToAppleCount(num digit) {
  return normalizeTargetCount(digit);
}
