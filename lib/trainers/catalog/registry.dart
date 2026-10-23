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
import 'package:larnes_mobile/trainers/mental_arithmetic/flash_cards/flash_cards_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/example_visualization_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/static_example_show_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/topic_chain_flash_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_table/topic_chain_table_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_find_tap_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_by_sound/letter_find_by_sound_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/letter_color_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_color/letter_case_color_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/letter_build_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_grid_match/letter_grid_match_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_match/letter_case_match_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_sound/letter_first_by_sound_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_complete/letter_complete_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_draw_show/letter_draw_show_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_half_draw/letter_half_draw_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_name_aloud/letter_name_aloud_trainer.dart';
import 'package:larnes_mobile/trainers/reading/stroop_colors/stroop_colors_trainer.dart';
import 'package:larnes_mobile/trainers/reading/schulte_table/schulte_table_trainer.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/wedge_tables_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_odd_one_out/letter_odd_one_out_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_marquee_tap/letter_marquee_tap_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_word_link/letter_word_link_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/letter_place_in_word_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_connect_dots/letter_connect_dots_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_shutter/reading_shutter_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_vanish/reading_vanish_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_upside_down/reading_upside_down_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_pace_track/reading_pace_track_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_noisy_text/reading_noisy_text_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_pointer/reading_pointer_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_blocks/reading_blocks_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_tree/reading_tree_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_flash/reading_flash_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_fixation/reading_fixation_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_diagonal/reading_diagonal_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_reread/reading_reread_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_echo/reading_echo_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_phrases/reading_phrases_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_find_span/reading_find_span_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_sprint/reading_word_sprint_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_cloze/reading_cloze_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_story_order/reading_story_order_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_main_idea/reading_main_idea_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_anagram/reading_anagram_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_maze/reading_word_maze_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_grid_mask/reading_grid_mask_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_snake/reading_snake_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_line_pace/reading_line_pace_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_orientation_pick/letter_orientation_pick_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_trace/letter_trace_trainer.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_trainer.dart';

typedef TrainerWidgetBuilder = Widget Function({
  required Map<String, dynamic> params,
  VoidCallback? onComplete,
});

final Map<TrainerKey, TrainerWidgetBuilder> trainerBuilders = {
  TrainerKey.numberRowShow: ({required params, onComplete}) =>
      NumberRowShowTrainer(params: params, onComplete: onComplete),
  TrainerKey.appleCountShow: ({required params, onComplete}) =>
      AppleCountShowTrainer(params: params, onComplete: onComplete),
  TrainerKey.flashCards: ({required params, onComplete}) =>
      FlashCardsTrainer(params: params, onComplete: onComplete),
  TrainerKey.dotsDigitAbacus: ({required params, onComplete}) =>
      DotsDigitAbacusTrainer(params: params, onComplete: onComplete),
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
  TrainerKey.exampleVisualization: ({required params, onComplete}) =>
      ExampleVisualizationTrainer(params: params, onComplete: onComplete),
  TrainerKey.staticExampleShow: ({required params, onComplete}) =>
      StaticExampleShowTrainer(params: params),
  TrainerKey.topicChainFlash: ({required params, onComplete}) =>
      TopicChainFlashTrainer(params: params, onComplete: onComplete),
  TrainerKey.topicChainTable: ({required params, onComplete}) =>
      TopicChainTableTrainer(params: params),
  TrainerKey.flyTrack: ({required params, onComplete}) =>
      FlyTrackTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterFindTap: ({required params, onComplete}) =>
      LetterFindTapTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterFindBySound: ({required params, onComplete}) =>
      LetterFindBySoundTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterTrace: ({required params, onComplete}) =>
      LetterTraceTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterHalfDraw: ({required params, onComplete}) =>
      LetterHalfDrawTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterColor: ({required params, onComplete}) =>
      LetterColorTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterCaseColor: ({required params, onComplete}) =>
      LetterCaseColorTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterBuild: ({required params, onComplete}) =>
      LetterBuildTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterGridMatch: ({required params, onComplete}) =>
      LetterGridMatchTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterCaseMatch: ({required params, onComplete}) =>
      LetterCaseMatchTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterOrientationPick: ({required params, onComplete}) =>
      LetterOrientationPickTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterFirstBySound: ({required params, onComplete}) =>
      LetterFirstBySoundTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterMarqueeTap: ({required params, onComplete}) =>
      LetterMarqueeTapTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterWordLink: ({required params, onComplete}) =>
      LetterWordLinkTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterComplete: ({required params, onComplete}) =>
      LetterCompleteTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterOddOneOut: ({required params, onComplete}) =>
      LetterOddOneOutTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterPlaceInWord: ({required params, onComplete}) =>
      LetterPlaceInWordTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterNameAloud: ({required params, onComplete}) =>
      LetterNameAloudTrainer(params: params, onComplete: onComplete),
  TrainerKey.stroopColors: ({required params, onComplete}) =>
      StroopColorsTrainer(params: params, onComplete: onComplete),
  TrainerKey.schulteTable: ({required params, onComplete}) =>
      SchulteTableTrainer(params: params, onComplete: onComplete),
  TrainerKey.wedgeTables: ({required params, onComplete}) =>
      WedgeTablesTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingShutter: ({required params, onComplete}) =>
      ReadingShutterTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingVanish: ({required params, onComplete}) =>
      ReadingVanishTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingUpsideDown: ({required params, onComplete}) =>
      ReadingUpsideDownTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingPaceTrack: ({required params, onComplete}) =>
      ReadingPaceTrackTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingNoisyText: ({required params, onComplete}) =>
      ReadingNoisyTextTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingPointer: ({required params, onComplete}) =>
      ReadingPointerTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingBlocks: ({required params, onComplete}) =>
      ReadingBlocksTrainer(params: params),
  TrainerKey.readingTree: ({required params, onComplete}) =>
      ReadingTreeTrainer(params: params),
  TrainerKey.readingFlash: ({required params, onComplete}) =>
      ReadingFlashTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingFixation: ({required params, onComplete}) =>
      ReadingFixationTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingDiagonal: ({required params, onComplete}) =>
      ReadingDiagonalTrainer(params: params),
  TrainerKey.readingReread: ({required params, onComplete}) =>
      ReadingRereadTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingEcho: ({required params, onComplete}) =>
      ReadingEchoTrainer(params: params),
  TrainerKey.readingPhrases: ({required params, onComplete}) =>
      ReadingPhrasesTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingFindSpan: ({required params, onComplete}) =>
      ReadingFindSpanTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingWordSprint: ({required params, onComplete}) =>
      ReadingWordSprintTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingCloze: ({required params, onComplete}) =>
      ReadingClozeTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingStoryOrder: ({required params, onComplete}) =>
      ReadingStoryOrderTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingMainIdea: ({required params, onComplete}) =>
      ReadingMainIdeaTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingAnagram: ({required params, onComplete}) =>
      ReadingAnagramTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingWordMaze: ({required params, onComplete}) =>
      ReadingWordMazeTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingGridMask: ({required params, onComplete}) =>
      ReadingGridMaskTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingSnake: ({required params, onComplete}) =>
      ReadingSnakeTrainer(params: params, onComplete: onComplete),
  TrainerKey.readingLinePace: ({required params, onComplete}) =>
      ReadingLinePaceTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterDrawShow: ({required params, onComplete}) =>
      LetterDrawShowTrainer(params: params, onComplete: onComplete),
  TrainerKey.letterConnectDots: ({required params, onComplete}) =>
      LetterConnectDotsTrainer(params: params, onComplete: onComplete),
};

final Map<TrainerKey, TrainerDefinition> trainerDefinitions = {
  TrainerKey.numberRowShow: TrainerDefinition(
    key: TrainerKey.numberRowShow,
    title: 'Числовой ряд',
    direction: TrainerDirection.math,
    isInteractive: true,
    validate: validateNumberRowShowParams,
  ),
  TrainerKey.appleCountShow: TrainerDefinition(
    key: TrainerKey.appleCountShow,
    title: 'Яблоки в корзине',
    direction: TrainerDirection.math,
    isInteractive: true,
    validate: validateAppleCountShowParams,
  ),
  TrainerKey.flashCards: TrainerDefinition(
    key: TrainerKey.flashCards,
    title: 'Флеш-карты',
    direction: TrainerDirection.mental,
    isInteractive: true,
    validate: validateFlashCardsParams,
  ),
  TrainerKey.dotsDigitAbacus: TrainerDefinition(
    key: TrainerKey.dotsDigitAbacus,
    title: 'Точки, цифра, абакус',
    direction: TrainerDirection.mental,
    isInteractive: true,
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
  TrainerKey.letterFirstBySound: TrainerDefinition(
    key: TrainerKey.letterFirstBySound,
    title: 'Первая буква слова по звуку',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterFirstBySoundParams,
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
  TrainerKey.stroopColors: TrainerDefinition(
    key: TrainerKey.stroopColors,
    title: 'Струп-тест',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateStroopColorsParams,
  ),
  TrainerKey.schulteTable: TrainerDefinition(
    key: TrainerKey.schulteTable,
    title: 'Таблица Шульте',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateSchulteTableParams,
  ),
  TrainerKey.wedgeTables: TrainerDefinition(
    key: TrainerKey.wedgeTables,
    title: 'Клиновидная таблица',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateWedgeTablesParams,
  ),
  TrainerKey.readingShutter: TrainerDefinition(
    key: TrainerKey.readingShutter,
    title: 'Шторка',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingShutterParams,
  ),
  TrainerKey.readingVanish: TrainerDefinition(
    key: TrainerKey.readingVanish,
    title: 'Исчезающий текст',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingVanishParams,
  ),
  TrainerKey.readingUpsideDown: TrainerDefinition(
    key: TrainerKey.readingUpsideDown,
    title: 'Вверх ногами',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingUpsideDownParams,
  ),
  TrainerKey.readingPaceTrack: TrainerDefinition(
    key: TrainerKey.readingPaceTrack,
    title: 'Обратный счет',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingPaceTrackParams,
  ),
  TrainerKey.readingNoisyText: TrainerDefinition(
    key: TrainerKey.readingNoisyText,
    title: 'Зашумленные тексты',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingNoisyTextParams,
  ),
  TrainerKey.readingPointer: TrainerDefinition(
    key: TrainerKey.readingPointer,
    title: 'Указка',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingPointerParams,
  ),
  TrainerKey.readingBlocks: TrainerDefinition(
    key: TrainerKey.readingBlocks,
    title: 'Блочное чтение',
    direction: TrainerDirection.speedReading,
    validate: validateReadingBlocksParams,
  ),
  TrainerKey.readingTree: TrainerDefinition(
    key: TrainerKey.readingTree,
    title: 'Ёлочка',
    direction: TrainerDirection.speedReading,
    validate: validateReadingTreeParams,
  ),
  TrainerKey.readingFlash: TrainerDefinition(
    key: TrainerKey.readingFlash,
    title: 'Вспышка',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingFlashParams,
  ),
  TrainerKey.readingFixation: TrainerDefinition(
    key: TrainerKey.readingFixation,
    title: 'Пачка в одной точке',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingFixationParams,
  ),
  TrainerKey.readingDiagonal: TrainerDefinition(
    key: TrainerKey.readingDiagonal,
    title: 'Чтение по диагонали',
    direction: TrainerDirection.speedReading,
    validate: validateReadingDiagonalParams,
  ),
  TrainerKey.readingReread: TrainerDefinition(
    key: TrainerKey.readingReread,
    title: 'Побей свой результат',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingRereadParams,
  ),
  TrainerKey.readingEcho: TrainerDefinition(
    key: TrainerKey.readingEcho,
    title: 'Эхо',
    direction: TrainerDirection.speedReading,
    validate: validateReadingEchoParams,
  ),
  TrainerKey.readingPhrases: TrainerDefinition(
    key: TrainerKey.readingPhrases,
    title: 'Смысловые фразы',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingPhrasesParams,
  ),
  TrainerKey.readingFindSpan: TrainerDefinition(
    key: TrainerKey.readingFindSpan,
    title: 'Найди слово',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingFindSpanParams,
  ),
  TrainerKey.readingWordSprint: TrainerDefinition(
    key: TrainerKey.readingWordSprint,
    title: 'Словесный спринт',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingWordSprintParams,
  ),
  TrainerKey.readingCloze: TrainerDefinition(
    key: TrainerKey.readingCloze,
    title: 'Пропущенное слово',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingClozeParams,
  ),
  TrainerKey.readingStoryOrder: TrainerDefinition(
    key: TrainerKey.readingStoryOrder,
    title: 'Собери историю',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingStoryOrderParams,
  ),
  TrainerKey.readingMainIdea: TrainerDefinition(
    key: TrainerKey.readingMainIdea,
    title: 'Главная мысль',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingMainIdeaParams,
  ),
  TrainerKey.readingAnagram: TrainerDefinition(
    key: TrainerKey.readingAnagram,
    title: 'Анаграммы',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateReadingAnagramParams,
  ),
  TrainerKey.readingWordMaze: TrainerDefinition(
    key: TrainerKey.readingWordMaze,
    title: 'Словесный лабиринт',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingWordMazeParams,
  ),
  TrainerKey.readingGridMask: TrainerDefinition(
    key: TrainerKey.readingGridMask,
    title: 'Рамка',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingGridMaskParams,
  ),
  TrainerKey.readingSnake: TrainerDefinition(
    key: TrainerKey.readingSnake,
    title: 'Змейка',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingSnakeParams,
  ),
  TrainerKey.readingLinePace: TrainerDefinition(
    key: TrainerKey.readingLinePace,
    title: 'Построчное чтение',
    direction: TrainerDirection.speedReading,
    isInteractive: true,
    validate: validateReadingLinePaceParams,
  ),
  TrainerKey.letterMarqueeTap: TrainerDefinition(
    key: TrainerKey.letterMarqueeTap,
    title: 'Бегущая строка',
    direction: TrainerDirection.reading,
    isInteractive: true,
    validate: validateLetterMarqueeTapParams,
  ),
  TrainerKey.staticExampleShow: TrainerDefinition(
    key: TrainerKey.staticExampleShow,
    title: 'Визуализация примера статично',
    direction: TrainerDirection.mental,
    validate: validateStaticExampleShowParams,
  ),
  TrainerKey.exampleVisualization: TrainerDefinition(
    key: TrainerKey.exampleVisualization,
    title: 'Визуализация примера',
    direction: TrainerDirection.mental,
    isInteractive: true,
    validate: validateExampleVisualizationParams,
  ),
  TrainerKey.topicChainFlash: TrainerDefinition(
    key: TrainerKey.topicChainFlash,
    title: 'Цепочка по теме',
    direction: TrainerDirection.mental,
    isInteractive: true,
    validate: validateTopicChainFlashParams,
  ),
  TrainerKey.topicChainTable: TrainerDefinition(
    key: TrainerKey.topicChainTable,
    title: 'Таблица цепочек',
    direction: TrainerDirection.mental,
    validate: validateTopicChainTableParams,
  ),
  TrainerKey.flyTrack: TrainerDefinition(
    key: TrainerKey.flyTrack,
    title: 'Муха',
    direction: TrainerDirection.intel,
    isInteractive: true,
    validate: validateFlyTrackParams,
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
