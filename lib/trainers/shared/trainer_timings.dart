/// Тайминги интерактивных тренажёров — сверка с web `component.tsx`.
///
/// Эталоны: `digit-find-tap`, `fruit-count-tap`, `number-composition`,
/// `flashcard-digit-match`, `digit-trace`, reading tap/match scenes.
abstract final class TrainerTimings {
  /// Shake / подсветка неверного ответа (tap-тренажёры).
  static const wrongFeedbackMs = 550;

  /// Красная вспышка неверного соединения / match (`flashcard-digit-match`, reading match).
  static const wrongFlashMs = 450;

  /// Alias для match-board (то же значение, что [wrongFlashMs]).
  static const wrongConnectionFlashMs = wrongFlashMs;

  /// Пауза между фазами (`number-composition`).
  static const phaseAdvanceMs = 800;

  /// Задержка перед `onComplete` — tap trainers без burst-анимации.
  static const completeDelayMs = 900;

  /// Burst при нахождении цифры/буквы (`digit-found-burst`, `letter-found-burst`).
  static const foundBurstMs = 520;

  /// `digit-find-tap`, `letter-find-tap`, `digit-trace` и др. с burst.
  static const completeAfterBurstMs = foundBurstMs + 180;

  /// `flashcard-digit-match` — короче, после соединения всех пар.
  static const flashcardCompleteDelayMs = 700;

  /// `letter-color`, `letter-case-color`.
  static const colorCompleteDelayMs = 300;

  /// `letter-build` — после сборки буквы по гайду.
  static const guideCompleteDelayMs = 600;
}
