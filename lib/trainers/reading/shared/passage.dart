import 'package:characters/characters.dart';

class ReadingPassageQuestion {
  const ReadingPassageQuestion({
    required this.prompt,
    required this.choices,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> choices;
  final int correctIndex;
}

class ReadingFindTask {
  const ReadingFindTask({required this.word, required this.answer});

  final String word;
  final List<String> answer;
}

class ReadingSprintTask {
  const ReadingSprintTask({required this.words, required this.sentences});

  final List<String> words;
  final List<String> sentences;
}

class ReadingClozeTask {
  const ReadingClozeTask({
    required this.prompt,
    required this.choices,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> choices;
  final int correctIndex;
}

class ReadingClozePair {
  const ReadingClozePair({required this.simple, required this.story});

  final ReadingClozeTask simple;
  final ReadingClozeTask story;
}

class ReadingMainIdea {
  const ReadingMainIdea({
    required this.choices,
    required this.correctIndex,
    required this.confirm,
  });

  final List<String> choices;
  final int correctIndex;
  final String confirm;
}

class ReadingMazeTask {
  const ReadingMazeTask({
    required this.path,
    required this.rule,
    required this.words,
  });

  final List<int> path;
  final String rule;
  final List<String> words;
}

class ReadingMaze {
  const ReadingMaze({required this.group, required this.sentence});

  final ReadingMazeTask group;
  final ReadingMazeTask sentence;
}

ReadingMaze readingMaze(List<String> groupWords, List<String> sentenceWords, List<int> sentencePath) {
  return ReadingMaze(
    group: ReadingMazeTask(path: const [0, 1, 2, 5, 8], rule: 'Животные', words: groupWords),
    sentence: ReadingMazeTask(path: sentencePath, rule: 'Собери предложение', words: sentenceWords),
  );
}

class ReadingPassage {
  const ReadingPassage({
    required this.id,
    required this.text,
    required this.question,
    required this.phrases,
    required this.find,
    required this.sprint,
    required this.cloze,
    required this.story,
    required this.idea,
    required this.maze,
  });

  final String id;
  final String text;
  final ReadingPassageQuestion question;
  final List<String> phrases;
  final ReadingFindTask find;
  final ReadingSprintTask sprint;
  final ReadingClozePair cloze;
  final List<String> story;
  final ReadingMainIdea idea;
  final ReadingMaze maze;
}

final readingPassages = <ReadingPassage>[
  ReadingPassage(
    id: 'short-window',
    text: 'Утром кот сел на окно и смотрел на тихий двор.',
    question: ReadingPassageQuestion(
      prompt: 'Что делал кот?',
      choices: ['Искал мяч', 'Смотрел на двор', 'Писал письмо'],
      correctIndex: 1,
    ),
    phrases: ['Утром', 'кот сел на окно', 'и смотрел на тихий двор.'],
    find: ReadingFindTask(word: 'окно', answer: ['смотрел', 'на', 'тихий', 'двор.']),
    sprint: ReadingSprintTask(
      words: ['кот', 'окно', 'тихий', 'смотрел'],
      sentences: ['Кот сел на окно.', 'Кот смотрел на тихий двор.'],
    ),
    cloze: ReadingClozePair(
      simple: ReadingClozeTask(
        prompt: 'Кот пьёт молоко из ….',
        choices: ['книги', 'миски', 'шапки'],
        correctIndex: 1,
      ),
      story: ReadingClozeTask(
        prompt: 'Кот смотрел на тихий ….',
        choices: ['мяч', 'хлеб', 'двор'],
        correctIndex: 2,
      ),
    ),
    story: [
      'Утром кот сел на окно.',
      'Он смотрел на тихий двор.',
      'Во дворе было тихо.',
      'Кот не сходил с окна.',
      'Так он сидел до обеда.',
    ],
    idea: ReadingMainIdea(
      choices: ['Кот смотрел на двор.', 'Двор был тихий.', 'Кот поймал птицу.'],
      correctIndex: 0,
      confirm: 'Утром кот сел на окно и смотрел на тихий двор.',
    ),
    maze: readingMaze(
      ['кот', 'пёс', 'лиса', 'окно', 'двор', 'волк', 'молоко', 'мяч', 'ёж'],
      ['Кот', 'сидел', 'двор', 'мяч', 'на', 'окно', 'молоко', 'окне.', 'пёс'],
      [0, 1, 4, 7],
    ),
  ),
  ReadingPassage(
    id: 'short-ball',
    text: 'Маша нашла красный мяч под старым кустом.',
    question: ReadingPassageQuestion(
      prompt: 'Что нашла Маша?',
      choices: ['Красный мяч', 'Синий шарф', 'Старую книгу'],
      correctIndex: 0,
    ),
    phrases: ['Маша нашла', 'красный мяч', 'под старым кустом.'],
    find: ReadingFindTask(word: 'мяч', answer: ['красный', 'мяч']),
    sprint: ReadingSprintTask(
      words: ['мяч', 'Маша', 'нашла', 'красный'],
      sentences: ['Маша нашла мяч.', 'Красный мяч.'],
    ),
    cloze: ReadingClozePair(
      simple: ReadingClozeTask(
        prompt: 'Чтобы рисовать, Маша взяла ….',
        choices: ['карандаш', 'тарелку', 'подушку'],
        correctIndex: 0,
      ),
      story: ReadingClozeTask(
        prompt: 'Под старым кустом лежал ….',
        choices: ['шарф', 'мяч', 'ковёр'],
        correctIndex: 1,
      ),
    ),
    story: [
      'Маша гуляла во дворе.',
      'Под старым кустом лежал мяч.',
      'Мяч был красный.',
      'Маша нашла мяч.',
      'Она взяла мяч с собой.',
    ],
    idea: ReadingMainIdea(
      choices: ['Куст был старый.', 'Маша купила мяч.', 'Маша нашла мяч.'],
      correctIndex: 2,
      confirm: 'Маша нашла красный мяч под старым кустом.',
    ),
    maze: readingMaze(
      ['кот', 'пёс', 'лиса', 'куст', 'мяч', 'волк', 'хлеб', 'дом', 'ёж'],
      ['Маша', 'нашла', 'куст', 'дом', 'мяч.', 'хлеб', 'пёс', 'стол', 'окно'],
      [0, 1, 4],
    ),
  ),
  ReadingPassage(
    id: 'medium-puddles',
    text: 'После дождя на дорожке блестели лужи. Дети пускали бумажные кораблики и громко смеялись.',
    question: ReadingPassageQuestion(
      prompt: 'Что делали дети?',
      choices: ['Сажали яблоню', 'Покупали хлеб', 'Пускали кораблики'],
      correctIndex: 2,
    ),
    phrases: [
      'После дождя',
      'на дорожке блестели лужи.',
      'Дети пускали бумажные кораблики',
      'и громко смеялись.',
    ],
    find: ReadingFindTask(word: 'кораблики', answer: ['пускали', 'бумажные', 'кораблики']),
    sprint: ReadingSprintTask(
      words: ['Дети', 'дождя', 'пускали', 'кораблики'],
      sentences: ['Дети пускали кораблики.', 'После дождя.'],
    ),
    cloze: ReadingClozePair(
      simple: ReadingClozeTask(
        prompt: 'После дождя Маша раскрыла ….',
        choices: ['шкаф', 'альбом', 'зонт'],
        correctIndex: 2,
      ),
      story: ReadingClozeTask(
        prompt: 'Дети пускали бумажные ….',
        choices: ['кораблики', 'яблоки', 'шапки'],
        correctIndex: 0,
      ),
    ),
    story: [
      'После дождя на дорожке блестели лужи.',
      'Дети вышли на дорожку.',
      'Они пускали бумажные кораблики.',
      'Кораблики плыли по лужам.',
      'Дети громко смеялись.',
    ],
    idea: ReadingMainIdea(
      choices: ['Кораблики были бумажные.', 'Дети играли после дождя.', 'Дети пошли в школу.'],
      correctIndex: 1,
      confirm: 'Дети пускали бумажные кораблики и громко смеялись.',
    ),
    maze: readingMaze(
      ['кот', 'пёс', 'лиса', 'лужа', 'дождь', 'волк', 'смех', 'дом', 'ёж'],
      ['Дети', 'лужа', 'дождь', 'пускали', 'смех', 'дом', 'кораблики.', 'мяч', 'кот'],
      [0, 3, 6],
    ),
  ),
  ReadingPassage(
    id: 'medium-market',
    text: 'На рынке бабушка купила яблоки, тёплый хлеб и кувшин молока. Домой она шла медленно и смотрела по сторонам.',
    question: ReadingPassageQuestion(
      prompt: 'Куда шла бабушка?',
      choices: ['В школу', 'Домой', 'К реке'],
      correctIndex: 1,
    ),
    phrases: [
      'На рынке',
      'бабушка купила яблоки, тёплый хлеб и кувшин молока.',
      'Домой она шла медленно',
      'и смотрела по сторонам.',
    ],
    find: ReadingFindTask(word: 'хлеб', answer: ['Домой']),
    sprint: ReadingSprintTask(
      words: ['хлеб', 'рынке', 'молока', 'бабушка'],
      sentences: ['На рынке бабушка купила хлеб.', 'Кувшин молока.'],
    ),
    cloze: ReadingClozePair(
      simple: ReadingClozeTask(
        prompt: 'Бабушка налила молоко в ….',
        choices: ['шапку', 'чашку', 'книгу'],
        correctIndex: 1,
      ),
      story: ReadingClozeTask(
        prompt: 'Домой бабушка несла тёплый ….',
        choices: ['мяч', 'зонт', 'хлеб'],
        correctIndex: 2,
      ),
    ),
    story: [
      'Бабушка пришла на рынок.',
      'Она купила яблоки и тёплый хлеб.',
      'В сумке был кувшин молока.',
      'Домой она шла медленно.',
      'Бабушка смотрела по сторонам.',
    ],
    idea: ReadingMainIdea(
      choices: ['Бабушка купила еду на рынке.', 'Хлеб был тёплый.', 'Бабушка встретила врача.'],
      correctIndex: 0,
      confirm: 'На рынке бабушка купила яблоки, тёплый хлеб и кувшин молока.',
    ),
    maze: readingMaze(
      ['кот', 'пёс', 'лиса', 'хлеб', 'молоко', 'волк', 'яблоко', 'рынок', 'ёж'],
      ['Бабушка', 'рынок', 'молоко', 'купила', 'яблоко', 'дом', 'хлеб.', 'мяч', 'кот'],
      [0, 3, 6],
    ),
  ),
  ReadingPassage(
    id: 'long-apple-tree',
    text:
        'В саду за домом росла старая яблоня. Летом под ней ставили стол, пили чай и слушали, как в ветках поёт дрозд. Вечером солнце садилось за крышу, и сад становился тихим.',
    question: ReadingPassageQuestion(
      prompt: 'Что росло в саду?',
      choices: ['Старая яблоня', 'Высокая берёза', 'Грядка моркови'],
      correctIndex: 0,
    ),
    phrases: [
      'В саду за домом',
      'росла старая яблоня.',
      'Летом под ней ставили стол,',
      'пили чай и слушали,',
      'как в ветках поёт дрозд.',
      'Вечером солнце садилось за крышу,',
      'и сад становился тихим.',
    ],
    find: ReadingFindTask(word: 'яблоня.', answer: ['старая', 'яблоня.']),
    sprint: ReadingSprintTask(
      words: ['чай', 'саду', 'крышу', 'старая', 'солнце'],
      sentences: ['В саду росла старая яблоня.', 'Пили чай.', 'Солнце садилось за крышу.'],
    ),
    cloze: ReadingClozePair(
      simple: ReadingClozeTask(
        prompt: 'В саду созрело спелое ….',
        choices: ['яблоко', 'кресло', 'окно'],
        correctIndex: 0,
      ),
      story: ReadingClozeTask(
        prompt: 'В саду росла старая ….',
        choices: ['берёза', 'яблоня', 'морковь'],
        correctIndex: 1,
      ),
    ),
    story: [
      'В саду за домом росла старая яблоня.',
      'Летом под ней ставили стол.',
      'За столом пили чай.',
      'В ветках пел дрозд.',
      'Вечером сад становился тихим.',
    ],
    idea: ReadingMainIdea(
      choices: ['В ветках пел дрозд.', 'В саду росла старая яблоня.', 'Дети собирали морковь.'],
      correctIndex: 1,
      confirm: 'В саду за домом росла старая яблоня.',
    ),
    maze: readingMaze(
      ['кот', 'пёс', 'лиса', 'сад', 'чай', 'волк', 'яблоня', 'стол', 'ёж'],
      ['В', 'чай', 'дрозд', 'саду', 'стол', 'дом', 'росла', 'яблоня.', 'кот'],
      [0, 3, 6, 7],
    ),
  ),
];

const defaultPassageId = 'short-window';

ReadingPassage? passageById(String id) {
  for (final passage in readingPassages) {
    if (passage.id == id) return passage;
  }
  return null;
}

class VanishUnit {
  const VanishUnit({required this.grapheme, required this.order});

  final String grapheme;
  final int order;
}

final letterGraphemePattern = RegExp(r'\p{L}', unicode: true);

bool isLetterGrapheme(String grapheme) => letterGraphemePattern.hasMatch(grapheme);

List<VanishUnit> buildVanishUnits(String text) {
  final units = <VanishUnit>[];
  final leading = <String>[];
  var order = 0;

  for (final grapheme in text.characters) {
    if (!isLetterGrapheme(grapheme)) {
      if (order == 0) {
        leading.add(grapheme);
      } else {
        units.add(VanishUnit(grapheme: grapheme, order: order));
      }
      continue;
    }

    order += 1;
    if (leading.isNotEmpty) {
      for (final pending in leading) {
        units.add(VanishUnit(grapheme: pending, order: order));
      }
      leading.clear();
    }
    units.add(VanishUnit(grapheme: grapheme, order: order));
  }

  if (leading.isNotEmpty) {
    for (final pending in leading) {
      units.add(VanishUnit(grapheme: pending, order: 1));
    }
  }

  return units;
}

int vanishLetterCount(List<VanishUnit> units) {
  var maxOrder = 0;
  for (final unit in units) {
    if (unit.order > maxOrder) maxOrder = unit.order;
  }
  return maxOrder;
}

int? passageIntValue(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.round();
  if (raw is String) return int.tryParse(raw.trim());
  return null;
}

String resolvePassageText(Map<String, dynamic> raw) {
  final source = raw['source'] == 'custom' ? 'custom' : 'bank';
  final customText = raw['customText']?.toString().trim() ?? '';
  if (source == 'custom') return customText;
  final passageId = raw['passageId']?.toString() ?? defaultPassageId;
  return passageById(passageId)?.text ?? '';
}

/// Returns an error message, or null when the passage fields are valid.
String? validatePassageAssignment(Map<String, dynamic> raw) {
  final source = raw['source'] == 'custom' ? 'custom' : 'bank';
  final pause = passageIntValue(raw['letterPauseMs']) ?? 180;
  if (pause < 80 || pause > 800) return 'Пауза на букву от 80 до 800 мс.';

  if (source == 'custom') {
    final text = raw['customText']?.toString().trim() ?? '';
    if (text.isEmpty) return 'Впишите текст.';
    if (text.length > 600) return 'Свой текст не длиннее 600 знаков.';
  } else if (passageById(raw['passageId']?.toString() ?? defaultPassageId) == null) {
    return 'Выберите текст из банка.';
  }

  return null;
}

class PassagePlay {
  const PassagePlay({
    required this.letterPauseMs,
    required this.text,
    required this.units,
  });

  final int letterPauseMs;
  final String text;
  final List<VanishUnit> units;

  int get letterCount => vanishLetterCount(units);
}

PassagePlay passagePlayFromParams(Map<String, dynamic> raw) {
  final pause = passageIntValue(raw['letterPauseMs']) ?? 180;
  final text = resolvePassageText(raw);
  return PassagePlay(
    letterPauseMs: pause.clamp(80, 800),
    text: text,
    units: buildVanishUnits(text),
  );
}

PassagePlay? passagePlayFromSnapshot(Map<String, dynamic>? payload) {
  if (payload == null) return null;
  final text = payload['text']?.toString() ?? '';
  final pause = passageIntValue(payload['letterPauseMs']);
  if (text.isEmpty || pause == null) return null;
  return PassagePlay(
    letterPauseMs: pause,
    text: text,
    units: buildVanishUnits(text),
  );
}
