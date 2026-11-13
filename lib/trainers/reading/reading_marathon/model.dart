export '../shared/word_list.dart' show validateReadingWordListRaw;
import 'package:larnes_mobile/trainers/audio/number_bank.dart';

const marathonDurations = [60000, 45000, 30000, 60000];
const marathonInstruction =
    'Прочитай как можно больше слов за одну минуту. Читай вслух. Когда прочитаешь слово, нажми «Далее».';
const marathonPrompts = [
  'explanation:reading-marathon:next-45',
  'explanation:reading-marathon:next-30',
  'explanation:reading-marathon:next-60',
];
const marathonFirst = 'feedback:reading-marathon:first',
    marathonLast = 'feedback:reading-marathon:last';
const morePrefix = 'feedback:reading:more',
    wordOne = 'feedback:reading:word-one',
    wordFew = 'feedback:reading:word-few',
    wordMany = 'feedback:reading:word-many';
const marathonPhrases = {
  'ru': [
    'Молодец! Теперь попробуй прочитать эти же слова за сорок пять секунд.',
    'Хорошо идёшь! Теперь попробуй прочитать эти же слова за тридцать секунд.',
    'Отличная работа! А теперь читай в таком же темпе целую минуту.',
    'Марафон завершён! Молодец! Твой результат за первую минуту —',
    'А за последнюю минуту —',
    'На',
    'слово больше!',
    'слова больше!',
    'слов больше!',
  ],
  'en': [
    'Well done! Now try reading the same words in forty-five seconds.',
    "You're doing well! Now try reading the same words in thirty seconds.",
    'Great work! Now keep reading at that pace for a whole minute.',
    'The marathon is complete! Well done! Your result for the first minute is',
    'And for the last minute',
    "That's",
    'more word!',
    '',
    'more words!',
  ],
  'ar': [
    'أحسنت! حاول الآن قراءة الكلمات نفسها خلال خمس وأربعين ثانية.',
    'أنت تبلي بلاءً حسناً! حاول الآن قراءة الكلمات نفسها خلال ثلاثين ثانية.',
    'عمل رائع! اقرأ الآن بالسرعة نفسها لمدة دقيقة كاملة.',
    'انتهى الماراثون! أحسنت! نتيجتك في الدقيقة الأولى هي',
    'وفي الدقيقة الأخيرة',
    'عدد الكلمات الإضافية',
    '',
    '',
    '',
  ],
};
String marathonCueText(String key, String lang) {
  final keys = [
    ...marathonPrompts,
    marathonFirst,
    marathonLast,
    morePrefix,
    wordOne,
    wordFew,
    wordMany,
  ];
  final i = keys.indexOf(key);
  return i < 0 ? '' : (marathonPhrases[lang] ?? marathonPhrases['ru']!)[i];
}

List<String>? marathonFinalKeys(List<int> counts, String locale) {
  final first = countedNumberAudioKeys(counts[0], locale),
      last = countedNumberAudioKeys(counts[3], locale),
      delta = counts[3] - counts[0];
  if (first.isEmpty || last.isEmpty) return null;
  final keys = [marathonFirst, ...first, marathonLast, ...last];
  if (delta > 0) {
    final amount = countedNumberAudioKeys(delta, locale, true);
    if (amount.isEmpty) return null;
    keys.addAll([morePrefix, ...amount]);
    if (!locale.startsWith('ar')) {
      final one = locale.startsWith('ru')
              ? delta % 10 == 1 && delta % 100 != 11
              : delta == 1,
          few =
              delta % 10 >= 2 &&
              delta % 10 <= 4 &&
              (delta % 100 < 12 || delta % 100 > 14);
      keys.add(
        one
            ? wordOne
            : locale.startsWith('ru') && few
            ? wordFew
            : wordMany,
      );
    }
  }
  return keys;
}

String marathonFinalText(List<int> counts, String lang) {
  final first = counts[0], last = counts[3], delta = last - first;
  var text =
      '${marathonCueText(marathonFirst, lang)} $first. ${marathonCueText(marathonLast, lang)} $last.';
  if (delta > 0) {
    final one = lang == 'ru'
            ? delta % 10 == 1 && delta % 100 != 11
            : delta == 1,
        few =
            delta % 10 >= 2 &&
            delta % 10 <= 4 &&
            (delta % 100 < 12 || delta % 100 > 14);
    text +=
        ' ${marathonCueText(morePrefix, lang)} $delta${lang == 'ar' ? '.' : ' ${marathonCueText(one
                  ? wordOne
                  : lang == 'ru' && few
                  ? wordFew
                  : wordMany, lang)}'}';
  }
  return text;
}
