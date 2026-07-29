/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/types.ts`

const signModes = ['mix', 'add', 'sub'];
const amountScopes = ['topic', 'withLower'];

const ACTION_COUNT_MIN = 3;
const ACTION_COUNT_MAX = 20;

typedef SignMode = String;
typedef AmountScope = String;
typedef TopicId = String;

class ChainStep {
  const ChainStep({
    required this.amount,
    required this.sign,
  });

  final int amount;
  final String sign;

  @override
  bool operator ==(Object other) {
    return other is ChainStep &&
        other.amount == amount &&
        other.sign == sign;
  }

  @override
  int get hashCode => Object.hash(amount, sign);
}

enum TechniqueKind { direct, brother, friend, friendBrother }

class Technique {
  const Technique.direct()
      : kind = TechniqueKind.direct,
        n = null;

  const Technique.brother(this.n) : kind = TechniqueKind.brother;

  const Technique.friend(this.n) : kind = TechniqueKind.friend;

  const Technique.friendBrother(this.n) : kind = TechniqueKind.friendBrother;

  final TechniqueKind kind;
  final int? n;

  @override
  bool operator ==(Object other) {
    return other is Technique && other.kind == kind && other.n == n;
  }

  @override
  int get hashCode => Object.hash(kind, n);
}

class GenerateConfig {
  const GenerateConfig({
    required this.actionCount,
    this.amountScope = 'withLower',
    required this.signMode,
    required this.topicId,
  });

  final int actionCount;
  final AmountScope amountScope;
  final SignMode signMode;
  final TopicId topicId;
}

typedef TopicAllows = bool Function(
  int value,
  ChainStep step,
  Technique technique,
);

typedef TopicChainValidator = bool Function(
  List<ChainStep> steps,
  List<int> intermediates,
);

class TopicRule {
  const TopicRule({
    required this.candidateAmounts,
    required this.totalRods,
    required this.allows,
    this.isValidChain,
    this.focusAmounts,
    this.focusTechniques,
    this.focusTechniqueN,
    this.focusCap,
  });

  final List<int> candidateAmounts;
  final int totalRods;
  final TopicAllows allows;
  final TopicChainValidator? isValidChain;

  /// Операнды «темы» (Просто N → [N]): при focusCap — pre-slot.
  final List<int>? focusAmounts;

  /// Целевые техники (Братья/Друзья): pre-slot по classify.
  final List<TechniqueKind>? focusTechniques;

  /// Curriculum: целевой N техники (brother-3 → 3). null = любой N (3digit).
  final int? focusTechniqueN;

  /// Default true if focusAmounts/focusTechniques set. false для Просто 1.
  final bool? focusCap;
}

class Chain {
  const Chain({
    required this.answer,
    required this.intermediates,
    required this.steps,
    required this.topicId,
  });

  final int answer;
  final List<int> intermediates;
  final List<ChainStep> steps;
  final TopicId topicId;
}

String formatChainStep(ChainStep step) => '${step.sign}${step.amount}';

String formatChainSteps(List<ChainStep> steps) =>
    steps.map(formatChainStep).join(' ');

bool isSignMode(String value) => signModes.contains(value);

bool isAmountScope(String value) => amountScopes.contains(value);

List<String> get knownSignModes => List.unmodifiable(signModes);

List<String> get knownAmountScopes => List.unmodifiable(amountScopes);

int get kActionCountMin => ACTION_COUNT_MIN;

int get kActionCountMax => ACTION_COUNT_MAX;
