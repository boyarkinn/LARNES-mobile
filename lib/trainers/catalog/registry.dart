import 'package:flutter/widgets.dart';
import 'package:larnes_mobile/trainers/catalog/reading_param_validators.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_definition.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_key.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_param_validators.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_trainer.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_trainer.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flashcard_digit_match_trainer.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_trace_trainer.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_pay_trainer.dart';
import 'package:larnes_mobile/trainers/math/number_composition/number_composition_trainer.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_show/abacus_show_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_trainer.dart';

typedef TrainerWidgetBuilder = Widget Function({
  required Map<String, dynamic> params,
  VoidCallback? onComplete,
});

final Map<TrainerKey, TrainerWidgetBuilder> trainerBuilders = {
  TrainerKey.numberRowShow: ({required params, onComplete}) =>
      NumberRowShowTrainer(params: params),
  TrainerKey.appleCountShow: ({required params, onComplete}) =>
      AppleCountShowTrainer(params: params),
  TrainerKey.abacusShow: ({required params, onComplete}) =>
      AbacusShowTrainer(params: params),
  TrainerKey.dotsDigitAbacus: ({required params, onComplete}) =>
      DotsDigitAbacusTrainer(params: params),
  TrainerKey.digitFindTap: ({required params, onComplete}) =>
      DigitFindTapTrainer(params: params, onComplete: onComplete),
  TrainerKey.fruitCountTap: ({required params, onComplete}) =>
      FruitCountTapTrainer(params: params, onComplete: onComplete),
  TrainerKey.numberComposition: ({required params, onComplete}) =>
      NumberCompositionTrainer(params: params, onComplete: onComplete),
  TrainerKey.shopPay: ({required params, onComplete}) =>
      ShopPayTrainer(params: params, onComplete: onComplete),
  TrainerKey.digitTrace: ({required params, onComplete}) =>
      DigitTraceTrainer(params: params, onComplete: onComplete),
  TrainerKey.flashcardDigitMatch: ({required params, onComplete}) =>
      FlashcardDigitMatchTrainer(params: params, onComplete: onComplete),
};

final Map<TrainerKey, TrainerDefinition> trainerDefinitions = {
  TrainerKey.numberRowShow: TrainerDefinition(
    key: TrainerKey.numberRowShow,
    title: 'Числовой ряд',
    direction: TrainerDirection.math,
    validate: validateNumberRowShowParams,
  ),
  TrainerKey.appleCountShow: TrainerDefinition(
    key: TrainerKey.appleCountShow,
    title: 'Яблоки в корзине',
    direction: TrainerDirection.math,
    validate: validateAppleCountShowParams,
  ),
  TrainerKey.abacusShow: TrainerDefinition(
    key: TrainerKey.abacusShow,
    title: 'Цифровой абакус',
    direction: TrainerDirection.mental,
    validate: validateAbacusShowParams,
  ),
  TrainerKey.dotsDigitAbacus: TrainerDefinition(
    key: TrainerKey.dotsDigitAbacus,
    title: 'Точки, цифра, абакус',
    direction: TrainerDirection.mental,
    validate: validateDotsDigitAbacusParams,
  ),
  TrainerKey.digitFindTap: TrainerDefinition(
    key: TrainerKey.digitFindTap,
    title: 'Найди цифру',
    direction: TrainerDirection.math,
    isInteractive: true,
    validate: validateDigitFindTapParams,
  ),
  TrainerKey.fruitCountTap: TrainerDefinition(
    key: TrainerKey.fruitCountTap,
    title: 'Арбузы',
    direction: TrainerDirection.math,
    isInteractive: true,
    validate: validateFruitCountTapParams,
  ),
  TrainerKey.numberComposition: TrainerDefinition(
    key: TrainerKey.numberComposition,
    title: 'Состав числа',
    direction: TrainerDirection.math,
    isInteractive: true,
    validate: validateNumberCompositionParams,
  ),
  TrainerKey.shopPay: TrainerDefinition(
    key: TrainerKey.shopPay,
    title: 'Магазин',
    direction: TrainerDirection.math,
    isInteractive: true,
    validate: validateShopPayParams,
  ),
  TrainerKey.digitTrace: TrainerDefinition(
    key: TrainerKey.digitTrace,
    title: 'Обведи цифру',
    direction: TrainerDirection.math,
    isInteractive: true,
    validate: validateDigitTraceParams,
  ),
  TrainerKey.flashcardDigitMatch: TrainerDefinition(
    key: TrainerKey.flashcardDigitMatch,
    title: 'Соедини флеш-карту с цифрой',
    direction: TrainerDirection.mental,
    isInteractive: true,
    validate: validateFlashcardDigitMatchParams,
  ),
  TrainerKey.letterFindTap: TrainerDefinition(
    key: TrainerKey.letterFindTap,
    title: 'Найди букву',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterFindTapParams,
  ),
  TrainerKey.letterFindBySound: TrainerDefinition(
    key: TrainerKey.letterFindBySound,
    title: 'Найди букву по звуку',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterFindBySoundParams,
  ),
  TrainerKey.letterTrace: TrainerDefinition(
    key: TrainerKey.letterTrace,
    title: 'Обведи букву',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterTraceParams,
  ),
  TrainerKey.letterHalfDraw: TrainerDefinition(
    key: TrainerKey.letterHalfDraw,
    title: 'Дорисуй половину буквы',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterHalfDrawParams,
  ),
  TrainerKey.letterColor: TrainerDefinition(
    key: TrainerKey.letterColor,
    title: 'Разукрась букву',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterColorParams,
  ),
  TrainerKey.letterCaseColor: TrainerDefinition(
    key: TrainerKey.letterCaseColor,
    title: 'Раскрась большую и маленькую буквы',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterCaseColorParams,
  ),
  TrainerKey.letterConnectDots: TrainerDefinition(
    key: TrainerKey.letterConnectDots,
    title: 'Соедини точки',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterConnectDotsParams,
  ),
  TrainerKey.letterBuild: TrainerDefinition(
    key: TrainerKey.letterBuild,
    title: 'Собери букву',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterBuildParams,
  ),
  TrainerKey.letterDrawShow: TrainerDefinition(
    key: TrainerKey.letterDrawShow,
    title: 'Графический образ буквы',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterDrawShowParams,
  ),
  TrainerKey.letterComplete: TrainerDefinition(
    key: TrainerKey.letterComplete,
    title: 'Допиши букву',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterCompleteParams,
  ),
  TrainerKey.letterOrientationPick: TrainerDefinition(
    key: TrainerKey.letterOrientationPick,
    title: 'Найди правильно написанную букву',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterOrientationPickParams,
  ),
  TrainerKey.letterOddOneOut: TrainerDefinition(
    key: TrainerKey.letterOddOneOut,
    title: 'Найди лишнюю букву',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterOddOneOutParams,
  ),
  TrainerKey.letterFirstByImage: TrainerDefinition(
    key: TrainerKey.letterFirstByImage,
    title: 'Первая буква по изображению',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterFirstByImageParams,
  ),
  TrainerKey.letterWordLink: TrainerDefinition(
    key: TrainerKey.letterWordLink,
    title: 'Соедини букву с предметом',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterWordLinkParams,
  ),
  TrainerKey.letterPlaceInWord: TrainerDefinition(
    key: TrainerKey.letterPlaceInWord,
    title: 'Поставь букву на место',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterPlaceInWordParams,
  ),
  TrainerKey.letterCaseMatch: TrainerDefinition(
    key: TrainerKey.letterCaseMatch,
    title: 'Соедини заглавную с маленькой',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterCaseMatchParams,
  ),
  TrainerKey.letterGridMatch: TrainerDefinition(
    key: TrainerKey.letterGridMatch,
    title: 'Сделай фигуры одинаковыми',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterGridMatchParams,
  ),
  TrainerKey.letterNameAloud: TrainerDefinition(
    key: TrainerKey.letterNameAloud,
    title: 'Назови буквы',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterNameAloudParams,
  ),
  TrainerKey.letterMarqueeTap: TrainerDefinition(
    key: TrainerKey.letterMarqueeTap,
    title: 'Бегущая строка',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterMarqueeTapParams,
  ),
};

TrainerDefinition? getTrainerDefinition(String trainerKey) {
  final key = TrainerKey.tryParse(trainerKey);
  if (key == null) {
    return null;
  }
  return trainerDefinitions[key];
}

bool isTrainerKey(String value) => TrainerKey.isRegistered(value);

bool hasTrainerBuilder(String trainerKey) {
  final key = TrainerKey.tryParse(trainerKey);
  return key != null && trainerBuilders.containsKey(key);
}

List<TrainerDefinition> listTrainerDefinitions() {
  return trainerDefinitions.values.toList();
}
