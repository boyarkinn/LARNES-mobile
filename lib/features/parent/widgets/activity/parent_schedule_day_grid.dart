import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/features/parent/theme/attendance_cell_colors.dart';
import 'package:larnes_mobile/features/parent/utils/parent_schedule_layout.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

/// Day schedule grid — web `ParentActivityScheduleDayView`.
class ParentScheduleDayGrid extends StatelessWidget {
  const ParentScheduleDayGrid({
    super.key,
    required this.page,
    required this.l10n,
    required this.onPrevDay,
    required this.onNextDay,
  });

  final ParentActivityScheduleDayPage page;
  final AppLocalizations l10n;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DayNav(
          weekdayLabel: page.weekdayLabel,
          dateLabel: page.dateLabel,
          isToday: page.isToday,
          prevLabel: l10n.parentActivitySchedulePrevDay,
          nextLabel: l10n.parentActivityScheduleNextDay,
          onPrevDay: onPrevDay,
          onNextDay: onNextDay,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: SizedBox(
              height: parentScheduleGridHeight,
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  height: parentScheduleGridHeight,
                  child: Stack(
                    children: [
                      for (var hour = parentScheduleStartHour;
                          hour <= parentScheduleEndHour;
                          hour++)
                        Positioned(
                          top: (hour - parentScheduleStartHour) * parentScheduleHourHeight - 8,
                          left: 0,
                          right: 0,
                          child: Text(
                            scheduleFormatHourLabel(hour),
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: ParentColors.inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DayColumn(
                    page: page,
                    emptyLabel: l10n.parentActivityScheduleEmpty,
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ],
    );
  }
}

class _DayNav extends StatelessWidget {
  const _DayNav({
    required this.weekdayLabel,
    required this.dateLabel,
    required this.isToday,
    required this.prevLabel,
    required this.nextLabel,
    required this.onPrevDay,
    required this.onNextDay,
  });

  final String weekdayLabel;
  final String dateLabel;
  final bool isToday;
  final String prevLabel;
  final String nextLabel;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        border: const Border(bottom: BorderSide(color: ParentColors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _NavButton(icon: Icons.chevron_left_rounded, label: prevLabel, onTap: onPrevDay),
            Expanded(
              child: Column(
                children: [
                  Text(
                    weekdayLabel,
                    style: textTheme.labelMedium?.copyWith(
                      color: ParentColors.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: textTheme.titleSmall?.copyWith(
                      color: isToday ? ParentColors.shellDeep : ParentColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _NavButton(icon: Icons.chevron_right_rounded, label: nextLabel, onTap: onNextDay),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ParentColors.line),
              color: ParentColors.surface,
            ),
            child: Icon(icon, size: 20, color: ParentColors.inkMuted),
          ),
        ),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.page,
    required this.emptyLabel,
  });

  final ParentActivityScheduleDayPage page;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: page.isToday ? ParentColors.shellSoft.withValues(alpha: 0.35) : ParentColors.surface,
        border: Border.all(color: ParentColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            for (var hour = parentScheduleStartHour; hour < parentScheduleEndHour; hour++) ...[
              Positioned(
                top: (hour - parentScheduleStartHour) * parentScheduleHourHeight,
                left: 0,
                right: 0,
                child: const Divider(height: 1, thickness: 1, color: ParentColors.line),
              ),
              Positioned(
                top: (hour - parentScheduleStartHour) * parentScheduleHourHeight +
                    parentScheduleHourHeight / 2,
                left: 0,
                right: 0,
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: ParentColors.line.withValues(alpha: 0.45),
                ),
              ),
            ],
            if (page.lessons.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    emptyLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ParentColors.inkMuted,
                    ),
                  ),
                ),
              )
            else
              for (final lesson in page.lessons)
                Positioned(
                  top: scheduleSlotTopPx(lesson.startTime),
                  left: 6,
                  right: 6,
                  height: scheduleSlotHeightPx(lesson.startTime, lesson.endTime),
                  child: _LessonCard(lesson: lesson),
                ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson});

  final ParentScheduleDayLesson lesson;

  @override
  Widget build(BuildContext context) {
    final colors = scheduleLessonColors(lesson.tone);
    final textTheme = Theme.of(context).textTheme;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lesson.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.primaryText,
                      height: 1.15,
                    ),
                  ),
                  Text(
                    lesson.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.secondaryText,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
              Text(
                '${lesson.startTime}–${lesson.endTime}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.primaryText,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
