/// Тайминги интерактивных тренажёров — порт констант из web `component.tsx`.
abstract final class TrainerTimings {
  /// Shake / подсветка неверного ответа (tap-тренажёры).
  static const wrongFeedbackMs = 550;

  /// Красная вспышка неверного соединения (`flashcard-digit-match`).
  static const wrongConnectionFlashMs = 450;

  /// Пауза между фазами (`number-composition`).
  static const phaseAdvanceMs = 800;

  /// Задержка перед `onComplete` — большинство interactive trainers.
  static const completeDelayMs = 900;

  /// `digit-trace` — даём время прочитать оценку.
  static const traceCompleteDelayMs = 1400;

  /// `flashcard-digit-match` — короче, после соединения всех пар.
  static const flashcardCompleteDelayMs = 700;
}
