class ReadingAnagramCard {
  const ReadingAnagramCard({
    required this.slug,
    required this.label,
    required this.definition,
    required this.sentence,
  });

  final String slug;
  final String label;
  final String definition;
  final String sentence;
}

const readingAnagramDefaultSlug = '16_кот';

const readingAnagramCards = <ReadingAnagramCard>[
  ReadingAnagramCard(
    slug: '16_кот',
    label: 'кот',
    definition: 'Домашнее животное, оно мяукает.',
    sentence: 'На окне сидел пушистый ….',
  ),
  ReadingAnagramCard(
    slug: '17_дом',
    label: 'дом',
    definition: 'Здание, где живут люди.',
    sentence: 'Семья живёт в большом ….',
  ),
  ReadingAnagramCard(
    slug: '24_мяч',
    label: 'мяч',
    definition: 'Круглый предмет для игры.',
    sentence: 'Дети играют в ….',
  ),
  ReadingAnagramCard(
    slug: '25_нос',
    label: 'нос',
    definition: 'Им чувствуют запах.',
    sentence: 'Запах чувствуют ….',
  ),
  ReadingAnagramCard(
    slug: '26_рак',
    label: 'рак',
    definition: 'Речной житель с клешнями.',
    sentence: 'В реке живёт ….',
  ),
];

ReadingAnagramCard? readingAnagramCardBySlug(String slug) {
  for (final card in readingAnagramCards) {
    if (card.slug == slug) return card;
  }
  return null;
}

const readingAnagramInstructionText = 'Собери слово';
const readingAnagramInstructionMs = 2400;

String readingAnagramHint(Object? raw) {
  return raw == 'definition' || raw == 'sentence' ? raw.toString() : 'picture';
}

List<int> readingAnagramOrder(int length) {
  if (length < 2) return List<int>.generate(length, (index) => index);
  return [...List<int>.generate(length - 1, (index) => index + 1), 0];
}

String? validateReadingAnagramRaw(Map<String, dynamic> raw) {
  final slug = raw['anagramSlug']?.toString() ?? readingAnagramDefaultSlug;
  if (readingAnagramCardBySlug(slug) == null) return 'Выберите слово из банка.';
  return null;
}
