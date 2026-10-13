// Инструкция 24 тренажёров чтения. Совпадает с web use-reading-passage-instruction.

import 'dart:async';

import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

const readingInstructionPhrases = <String, Map<String, String>>{
  'reading-vanish': {'ar': 'اقرأ، سيختفي النص', 'en': 'Read, the text will disappear', 'ru': 'Читай, текст будет исчезать'},
  'reading-shutter': {'ar': 'اقرأ، جزء من النص مغطى', 'en': 'Read, part of the text is covered', 'ru': 'Читай, часть текста закрыта'},
  'reading-upside-down': {'ar': 'اقرأ، النص مقلوب', 'en': 'Read, the text is upside down', 'ru': 'Читай, текст перевёрнут'},
  'reading-pace-track': {'ar': 'اقرأ بالإيقاع', 'en': 'Read in rhythm', 'ru': 'Читай в ритме'},
  'reading-noisy-text': {'ar': 'اقرأ، النص مشوش', 'en': 'Read, the text has noise', 'ru': 'Читай, текст с помехами'},
  'reading-pointer': {'ar': 'اقرأ، المؤشر يدل على الحرف', 'en': 'Read, the pointer shows the letter', 'ru': 'Читай, указка показывает букву'},
  'reading-blocks': {'ar': 'اقرأ سطراً سطراً', 'en': 'Read line by line', 'ru': 'Читай по строкам'},
  'reading-tree': {'ar': 'اقرأ على شكل الشجرة', 'en': 'Read along the tree shape', 'ru': 'Читай по ёлочке'},
  'reading-flash': {'ar': 'اقرأ الومضة', 'en': 'Read the flash', 'ru': 'Читай вспышку'},
  'reading-fixation': {'ar': 'اقرأ في نقطة واحدة', 'en': 'Read at one point', 'ru': 'Читай в одной точке'},
  'reading-diagonal': {'ar': 'اقرأ على القطر', 'en': 'Read along the diagonal', 'ru': 'Читай по диагонали'},
  'reading-reread': {'ar': 'اقرأ بصوت عالٍ مرتين', 'en': 'Read aloud twice', 'ru': 'Читай вслух два раза'},
  'reading-echo': {'ar': 'ردد بعد النص', 'en': 'Repeat after the text', 'ru': 'Повторяй за текстом'},
  'reading-phrases': {'ar': 'اقرأ حسب المعنى', 'en': 'Read by meaning', 'ru': 'Читай по смыслу'},
  'reading-find-span': {'ar': 'جده في النص', 'en': 'Find it in the text', 'ru': 'Найди в тексте'},
  'reading-word-sprint': {'ar': 'اقرأ الكلمات', 'en': 'Read the words', 'ru': 'Читай слова'},
  'reading-cloze': {'ar': 'اختر الكلمة', 'en': 'Choose the word', 'ru': 'Выбери слово'},
  'reading-story-order': {'ar': 'رتب القصة', 'en': 'Put the story in order', 'ru': 'Собери историю'},
  'reading-main-idea': {'ar': 'اختر الفكرة', 'en': 'Choose the main idea', 'ru': 'Выбери мысль'},
  'reading-anagram': {'ar': 'ركّب الكلمة', 'en': 'Build the word', 'ru': 'Собери слово'},
  'reading-word-maze': {'ar': 'اتبع الطريق', 'en': 'Follow the path', 'ru': 'Веди путь'},
  'reading-grid-mask': {'ar': 'اقرأ عبر الشبكة', 'en': 'Read through the grid', 'ru': 'Читай сквозь сетку'},
  'reading-snake': {'ar': 'انظر إلى الرأس', 'en': 'Watch the head', 'ru': 'Смотри на головку'},
  'reading-line-pace': {'ar': 'اقرأ السطر في الوقت', 'en': 'Read the line in time', 'ru': 'Успей прочитать строку'},
};

class ReadingInstructionPlayback {
  const ReadingInstructionPlayback({required this.durationMs, required this.text, this.filePath});

  final int durationMs;
  final String? filePath;
  final String text;
}

ReadingInstructionPlayback readingInstructionPlayback({
  required String trainerKey,
  required String fallbackText,
  required int fallbackMs,
}) {
  final file = speechAudioFile('instruction:$trainerKey');
  final phrases = readingInstructionPhrases[trainerKey];
  String? localeText;
  if (file != null && phrases != null) {
    if (file.locale == 'en-US') {
      localeText = phrases['en'];
    } else if (file.locale == 'ar-XA') {
      localeText = phrases['ar'];
    } else {
      localeText = phrases['ru'];
    }
  }

  if (file != null && file.durationMs > 0) {
    final published = file.text.trim();
    return ReadingInstructionPlayback(
      durationMs: file.durationMs,
      filePath: file.path,
      text: published.isNotEmpty
          ? published
          : (localeText == null || localeText.isEmpty)
              ? fallbackText
              : localeText,
    );
  }

  return ReadingInstructionPlayback(durationMs: fallbackMs, text: fallbackText);
}

/// Возвращает отмену. Без файла остаётся прежний таймер и текст, сеть не открывается.
void Function() startReadingInstruction({
  required String trainerKey,
  required String fallbackText,
  required int fallbackMs,
  required bool reduceMotion,
  required bool Function() isMounted,
  required void Function(String text, int length) onFrame,
  required void Function() onFinished,
}) {
  final playback = readingInstructionPlayback(
    fallbackMs: fallbackMs,
    fallbackText: fallbackText,
    trainerKey: trainerKey,
  );
  var length = 0;
  onFrame(playback.text, 0);
  final stepMs = playback.text.isEmpty
      ? playback.durationMs
      : (playback.durationMs / playback.text.length).round().clamp(16, 400);
  final typeTimer = Timer.periodic(Duration(milliseconds: reduceMotion ? 16 : stepMs), (timer) {
    if (!isMounted()) {
      return;
    }
    if (length >= playback.text.length) {
      timer.cancel();
      return;
    }
    length += 1;
    onFrame(playback.text, length);
  });
  var finished = false;
  Timer? safety;
  Timer? prepareCap;

  void finish() {
    if (finished || !isMounted()) {
      return;
    }
    finished = true;
    typeTimer.cancel();
    safety?.cancel();
    prepareCap?.cancel();
    onFinished();
  }

  if (playback.filePath == null) {
    safety = Timer(Duration(milliseconds: playback.durationMs), finish);
  } else {
    final path = playback.filePath!;
    prepareCap = Timer(const Duration(seconds: 10), () {
      if (finished) {
        return;
      }
      unawaited(getSharedClipPlayer().cancel());
      finish();
    });
    unawaited(getSharedClipPlayer().play([path], playbackRate: 1, onStarted: () {
      if (finished || !isMounted()) {
        return;
      }
      prepareCap?.cancel();
      safety = Timer(Duration(milliseconds: playback.durationMs + 400), () {
        unawaited(getSharedClipPlayer().cancel());
        finish();
      });
    }).then((_) {
      prepareCap?.cancel();
      safety?.cancel();
      finish();
    }));
  }

  return () {
    finished = true;
    typeTimer.cancel();
    safety?.cancel();
    prepareCap?.cancel();
    if (playback.filePath != null) {
      unawaited(getSharedClipPlayer().cancel());
    }
  };
}
