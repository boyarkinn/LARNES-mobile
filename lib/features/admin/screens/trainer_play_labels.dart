import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

String trainerPlayFieldLabel(AppLocalizations l10n, String labelKey) {
  switch (labelKey) {
    case 'letterCaseLabel':
      return l10n.adminTrainerPlayLetterCaseLabel;
    case 'wordCaseLabel':
      return l10n.adminTrainerPlayWordCaseLabel;
    case 'letterLabel':
      return l10n.adminTrainerPlayLetterLabel;
    case 'practiceLettersLabel':
      return l10n.adminTrainerPlayPracticeLettersLabel;
    case 'shopItemLabel':
      return l10n.adminTrainerPlayShopItemLabel;
    case 'priceLabel':
      return l10n.adminTrainerPlayPriceLabel;
    case 'coinCountLabel':
      return l10n.adminTrainerPlayCoinCountLabel;
    case 'wholeLabel':
      return l10n.adminTrainerPlayWholeLabel;
    case 'knownPartLabel':
      return l10n.adminTrainerPlayKnownPartLabel;
    case 'answerRangeStartLabel':
      return l10n.adminTrainerPlayAnswerRangeStartLabel;
    case 'targetFruitLabel':
      return l10n.adminTrainerPlayTargetFruitLabel;
    case 'fruitTargetCountLabel':
      return l10n.adminTrainerPlayFruitTargetCountLabel;
    case 'fruitTypeCountLabel':
      return l10n.adminTrainerPlayFruitTypeCountLabel;
    case 'totalFruitsLabel':
      return l10n.adminTrainerPlayTotalFruitsLabel;
    case 'digitLabel':
      return l10n.adminTrainerPlayDigitLabel;
    case 'targetCountLabel':
      return l10n.adminTrainerPlayTargetCountLabel;
    case 'distractorCountLabel':
      return l10n.adminTrainerPlayDistractorCountLabel;
    case 'missingSegmentLabel':
      return l10n.adminTrainerPlayMissingSegmentLabel;
    case 'letterCountLabel':
      return l10n.adminTrainerPlayLetterCountLabel;
    case 'oddLetterLabel':
      return l10n.adminTrainerPlayOddLetterLabel;
    case 'optionCountLabel':
      return l10n.adminTrainerPlayOptionCountLabel;
    case 'dotModeLabel':
      return l10n.adminTrainerPlayDotModeLabel;
    case 'roundsLabel':
      return l10n.adminTrainerPlayRoundsLabel;
    case 'displaySecondsLabel':
      return l10n.adminTrainerPlayDisplaySecondsLabel;
    case 'gridSizeLabel':
      return l10n.adminTrainerPlayGridSizeLabel;
    case 'filledCountLabel':
      return l10n.adminTrainerPlayFilledCountLabel;
    case 'wordSlugLabel':
      return l10n.adminTrainerPlayWordSlugLabel;
    case 'entityCountLabel':
      return l10n.adminTrainerPlayEntityCountLabel;
    case 'pairCountLabel':
      return l10n.adminTrainerPlayPairCountLabel;
    case 'catchCountLabel':
      return l10n.adminTrainerPlayCatchCountLabel;
    case 'speedLabel':
      return l10n.adminTrainerPlaySpeedLabel;
    case 'wordItemCountLabel':
      return l10n.adminTrainerPlayWordItemCountLabel;
    case 'totalRodsLabel':
      return l10n.adminTrainerPlayTotalRodsLabel;
    case 'stepPauseSecLabel':
      return l10n.adminTrainerPlayStepPauseSecLabel;
    case 'exampleStringLabel':
      return l10n.adminTrainerPlayExampleStringLabel;
    case 'chainTopicIdLabel':
      return l10n.adminTrainerPlayChainTopicIdLabel;
    case 'solveModeLabel':
      return l10n.adminTrainerPlaySolveModeLabel;
    case 'actionCountLabel':
      return l10n.adminTrainerPlayActionCountLabel;
    case 'exampleCountLabel':
      return l10n.adminTrainerPlayExampleCountLabel;
    case 'signModeLabel':
      return l10n.adminTrainerPlaySignModeLabel;
    case 'amountScopeLabel':
      return l10n.adminTrainerPlayAmountScopeLabel;
    case 'valueLabel':
      return l10n.adminTrainerPlayValueLabel;
    case 'matchValue1Label':
      return l10n.adminTrainerPlayMatchValue1Label;
    case 'matchValue2Label':
      return l10n.adminTrainerPlayMatchValue2Label;
    case 'matchValue3Label':
      return l10n.adminTrainerPlayMatchValue3Label;
    case 'matchValue4Label':
      return l10n.adminTrainerPlayMatchValue4Label;
    default:
      return labelKey;
  }
}

String trainerPlayOptionLabel(AppLocalizations l10n, TrainerPlayFieldOption option) {
  if (option.label != null && option.label!.isNotEmpty) {
    return option.label!;
  }

  switch (option.labelKey) {
    case 'letterCaseUpper':
      return l10n.adminTrainerPlayLetterCaseUpper;
    case 'letterCaseLower':
      return l10n.adminTrainerPlayLetterCaseLower;
    case 'missingSegmentRandom':
      return l10n.adminTrainerPlayMissingSegmentRandom;
    case 'missingSegmentIndex1':
      return l10n.adminTrainerPlayMissingSegmentIndex1;
    case 'missingSegmentIndex2':
      return l10n.adminTrainerPlayMissingSegmentIndex2;
    case 'missingSegmentIndex3':
      return l10n.adminTrainerPlayMissingSegmentIndex3;
    case 'missingSegmentIndex4':
      return l10n.adminTrainerPlayMissingSegmentIndex4;
    case 'dotModeNumbered':
      return l10n.adminTrainerPlayDotModeNumbered;
    case 'dotModeFree':
      return l10n.adminTrainerPlayDotModeFree;
    case 'speedSlow':
      return l10n.adminTrainerPlaySpeedSlow;
    case 'speedMedium':
      return l10n.adminTrainerPlaySpeedMedium;
    case 'speedFast':
      return l10n.adminTrainerPlaySpeedFast;
    case 'solveModeAbacus':
      return l10n.adminTrainerPlaySolveModeAbacus;
    case 'solveModeMental':
      return l10n.adminTrainerPlaySolveModeMental;
    default:
      return option.value;
  }
}

bool trainerPlayFieldVisible(TrainerPlayConfig config, TrainerPlayField field, Map<String, String> values) {
  if (!field.isVisible(values)) {
    return false;
  }

  if (config.trainerKey != 'flashcard-digit-match') {
    return true;
  }

  if (!field.key.startsWith('value')) {
    return true;
  }

  final index = int.tryParse(field.key.replaceFirst('value', '')) ?? 0;
  final pairCount = int.tryParse(values['pairCount'] ?? '2') ?? 2;
  return index < pairCount;
}
