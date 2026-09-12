import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/abacus_match_card.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_sizes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/match_task_board.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/match_task_model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/triple_scene.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/triple_scene_layout.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_hud_inset.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/theme/trainer_direction_theme.dart';

/// One mounted scene for explain → task instruction → match.
///
/// The target dots, digit and abacus live in [_SharedRepresentationLayer] for
/// the whole experience. Their [AnimatedPositioned] elements move between
/// explain and practice geometry; [MatchTaskBoard] keeps matching anchors and
/// hit testing underneath without painting duplicate target objects.
class DotsDigitAbacusExperienceScene extends StatelessWidget {
  const DotsDigitAbacusExperienceScene({
    super.key,
    required this.completed,
    required this.connections,
    required this.disabled,
    required this.onAllConnected,
    required this.onConnect,
    required this.plan,
    required this.practice,
    required this.taskInstructionLength,
    required this.taskInstructionVisible,
    required this.visibility,
  });

  final bool completed;
  final List<MatchTaskConnection> connections;
  final bool disabled;
  final VoidCallback onAllConnected;
  final ValueChanged<MatchTaskConnection> onConnect;
  final MatchTaskPlan plan;
  final bool practice;
  final int taskInstructionLength;
  final bool taskInstructionVisible;
  final TripleSceneVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final directionTheme = TrainerDirectionThemeScope.maybeOf(context)?.theme;

    return AnimatedScale(
      key: const Key('dots-digit-abacus-experience-scene'),
      scale: completed && !reduceMotion ? 0.985 : 1,
      duration: Duration(milliseconds: reduceMotion ? 0 : 310),
      curve: Curves.easeOutCubic,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MatchTaskBoard(
            completed: false,
            connections: connections,
            disabled: disabled || !practice,
            onAllConnected: onAllConnected,
            onConnect: onConnect,
            plan: plan,
            preview: !practice || taskInstructionVisible,
            renderSharedObjects: false,
          ),
          IgnorePointer(
            child: _SharedRepresentationLayer(
              connections: connections,
              plan: plan,
              practice: practice,
              visibility: visibility,
            ),
          ),
          if (taskInstructionVisible)
            ColoredBox(
              color: (directionTheme?.surface ?? const Color(0xFFF4F0FF))
                  .withValues(alpha: 0.82),
              child: TrainerInstructionScene(
                length: taskInstructionLength,
                text: kDotsDigitAbacusTaskInstructionText,
              ),
            ),
        ],
      ),
    );
  }
}

class _SharedRepresentationLayer extends StatelessWidget {
  const _SharedRepresentationLayer({
    required this.connections,
    required this.plan,
    required this.practice,
    required this.visibility,
  });

  static const _transitionDuration = Duration(milliseconds: 680);

  final List<MatchTaskConnection> connections;
  final MatchTaskPlan plan;
  final bool practice;
  final TripleSceneVisibility visibility;

  bool get _digitConnected => connections.any(
    (connection) => connection.kind == MatchTaskConnectionKind.dotsDigit,
  );

  bool get _abacusConnected => connections.any(
    (connection) => connection.kind == MatchTaskConnectionKind.digitAbacus,
  );

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : _transitionDuration;
    const objectColor = Color(kDotsDigitAbacusObjectColor);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final explainLayout = computeTripleSceneLayout(
          viewportWidth: width,
          viewportHeight: height,
          dotCount: plan.dotsValue,
        );
        final practiceLayout = computeMatchTaskBoardLayout(
          viewportWidth: width,
          viewportHeight: height,
          dotCount: plan.dotsValue,
        );
        final hudInset = computeTrainerPlayHudSideInset(context);
        final availableWidth = math.max(0.0, width - hudInset * 2);
        final practiceColumnWidth =
            (availableWidth - practiceLayout.columnGap * 2) / 3;
        final targetDigitIndex = plan.digitItems.indexWhere(
          (item) => item.isTarget,
        );
        final targetDigitColor = targetDigitIndex < 0
            ? objectColor
            : Color(plan.digitItems[targetDigitIndex].displayColor);
        final targetAbacusIndex = plan.abacusItems.indexWhere(
          (item) => item.isTarget,
        );

        final dotsRect = practice
            ? _practiceRect(
                column: 0,
                columnWidth: practiceColumnWidth,
                height: practiceLayout.dotFrameHeight,
                hudInset: hudInset,
                itemWidth: practiceLayout.dotFrameWidth,
                stageHeight: height,
                columnGap: practiceLayout.columnGap,
              )
            : _centeredRect(
                center: Offset(width / 6, height / 2),
                width: explainLayout.dotFrameWidth,
                height: explainLayout.dotFrameHeight,
              );
        final digitRect = practice
            ? _practiceOptionRect(
                column: 1,
                columnWidth: practiceColumnWidth,
                hudInset: hudInset,
                itemHeight: practiceLayout.digitSize,
                itemWidth: practiceLayout.digitSize,
                optionIndex: targetDigitIndex,
                rowGap: practiceLayout.rowGap,
                stageHeight: height,
                columnGap: practiceLayout.columnGap,
              )
            : _centeredRect(
                center: Offset(width / 2, height / 2),
                width: explainLayout.digitCardSize,
                height: explainLayout.digitCardSize,
              );
        final abacusRect = practice
            ? _practiceOptionRect(
                column: 2,
                columnWidth: practiceColumnWidth,
                hudInset: hudInset,
                itemHeight: practiceLayout.abacusHeight,
                itemWidth: practiceLayout.abacusWidth,
                optionIndex: targetAbacusIndex,
                rowGap: practiceLayout.rowGap,
                stageHeight: height,
                columnGap: practiceLayout.columnGap,
              )
            : _centeredRect(
                center: Offset(width * 5 / 6, height / 2),
                width: explainLayout.abacusWidth,
                height: explainLayout.abacusHeight,
              );

        return Stack(
          key: const Key('dots-digit-abacus-shared-object-layer'),
          children: [
            AnimatedPositioned.fromRect(
              key: const Key('shared-dots-object'),
              rect: dotsRect,
              duration: duration,
              curve: Curves.easeInOutCubicEmphasized,
              child: AnimatedOpacity(
                opacity: practice || visibility.showDots ? 1 : 0,
                duration: duration,
                child: DotsDigitAbacusAnimatedDots(
                  count: plan.dotsValue,
                  height: dotsRect.height,
                  visibleCount: practice
                      ? plan.dotsValue
                      : visibility.visibleDotCount,
                  width: dotsRect.width,
                ),
              ),
            ),
            AnimatedPositioned.fromRect(
              key: const Key('shared-digit-object'),
              rect: digitRect,
              duration: duration,
              curve: Curves.easeInOutCubicEmphasized,
              child: AnimatedOpacity(
                opacity: practice || visibility.showDigit ? 1 : 0,
                duration: duration,
                child: AnimatedContainer(
                  duration: duration,
                  decoration: BoxDecoration(
                    color: practice
                        ? _digitConnected
                              ? const Color(0x4074E5A0)
                              : const Color(0x59F8FAFC)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(practice ? 16 : 0),
                    border: practice
                        ? Border.all(
                            color: _digitConnected
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFCBD5E1),
                            width: _digitConnected ? 2 : 1,
                          )
                        : null,
                  ),
                  padding: EdgeInsets.all(practice ? 8 : 0),
                  child: DotsDigitAbacusDrawnDigit(
                    color: practice ? targetDigitColor : objectColor,
                    value: plan.targetValue,
                  ),
                ),
              ),
            ),
            AnimatedPositioned.fromRect(
              key: const Key('shared-abacus-object'),
              rect: abacusRect,
              duration: duration,
              curve: Curves.easeInOutCubicEmphasized,
              child: AnimatedOpacity(
                opacity: practice || visibility.showAbacus ? 1 : 0,
                duration: duration,
                child: AbacusMatchCard(
                  connected: _abacusConnected,
                  framed: practice,
                  height: math.max(0, abacusRect.height - (practice ? 18 : 0)),
                  value: plan.targetValue,
                  width: abacusRect.width,
                ),
              ),
            ),
            for (final equals in [
              (
                key: const Key('shared-left-equals'),
                left: width / 3 - 17,
                visible: visibility.showDigitEquals,
              ),
              (
                key: const Key('shared-right-equals'),
                left: width * 2 / 3 - 17,
                visible: visibility.showAbacusEquals,
              ),
            ])
              AnimatedPositioned(
                key: equals.key,
                left: equals.left,
                top: height / 2 - 14,
                width: 34,
                height: 28,
                duration: duration,
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: !practice && equals.visible ? 1 : 0,
                  duration: duration,
                  child: const DotsDigitAbacusDrawnEquals(color: objectColor),
                ),
              ),
          ],
        );
      },
    );
  }

  Rect _centeredRect({
    required Offset center,
    required double width,
    required double height,
  }) {
    return Rect.fromCenter(center: center, width: width, height: height);
  }

  Rect _practiceRect({
    required int column,
    required double columnWidth,
    required double height,
    required double hudInset,
    required double itemWidth,
    required double stageHeight,
    required double columnGap,
  }) {
    final left =
        hudInset +
        column * (columnWidth + columnGap) +
        (columnWidth - itemWidth) / 2;
    return Rect.fromLTWH(left, (stageHeight - height) / 2, itemWidth, height);
  }

  Rect _practiceOptionRect({
    required int column,
    required double columnWidth,
    required double hudInset,
    required double itemHeight,
    required double itemWidth,
    required int optionIndex,
    required double rowGap,
    required double stageHeight,
    required double columnGap,
  }) {
    final safeIndex = optionIndex < 0 ? 0 : optionIndex;
    final stackHeight = itemHeight * 3 + rowGap * 2;
    final left =
        hudInset +
        column * (columnWidth + columnGap) +
        (columnWidth - itemWidth) / 2;
    final top =
        (stageHeight - stackHeight) / 2 + safeIndex * (itemHeight + rowGap);
    return Rect.fromLTWH(left, top, itemWidth, itemHeight);
  }
}
