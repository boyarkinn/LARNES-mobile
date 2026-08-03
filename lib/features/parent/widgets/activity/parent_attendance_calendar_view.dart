import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/features/parent/theme/attendance_cell_colors.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

/// Read-only месячный календарь — web `ParentAttendanceCalendar`.
class ParentAttendanceCalendarView extends StatelessWidget {
  const ParentAttendanceCalendarView({
    super.key,
    required this.page,
    required this.l10n,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final ParentAttendanceCalendarPage page;
  final AppLocalizations l10n;
  final VoidCallback? onPrevMonth;
  final VoidCallback? onNextMonth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: ParentColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ParentColors.line),
          ),
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthNav(
                title: page.monthLabel,
                onPrev: onPrevMonth,
                onNext: onNextMonth,
                prevLabel: l10n.parentActivityCalendarPrevMonth,
                nextLabel: l10n.parentActivityCalendarNextMonth,
              ),
              const SizedBox(height: 12),
              _WeekdayRow(labels: page.weekdayLabels),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.92,
                ),
                itemCount: page.gridCells.length,
                itemBuilder: (context, index) {
                  final cell = page.gridCells[index];
                  if (cell == null) {
                    return const SizedBox.shrink();
                  }
                  return _CalendarCell(cell: cell);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _LegendItem(
              color: attendanceCalendarLegendPaid,
              label: l10n.parentActivityCalendarLegendPaid,
            ),
            _LegendItem(
              color: attendanceCalendarLegendFirstUnpaid,
              label: l10n.parentActivityCalendarLegendFirstUnpaid,
            ),
            _LegendItem(
              color: attendanceCalendarLegendUnpaid,
              label: l10n.parentActivityCalendarLegendUnpaid,
            ),
            if (page.showMakeupLegend)
              _LegendItem(
                color: attendanceCalendarLegendMakeup,
                label: l10n.parentActivityCalendarLegendMakeup,
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          l10n.parentActivityCalendarCodesTitle,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: ParentColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        _CodeLegendItem(code: '1', label: l10n.parentActivityCalendarCodePresent),
        _CodeLegendItem(code: 'Н', label: l10n.parentActivityCalendarCodeAbsent),
        _CodeLegendItem(code: 'Б', label: l10n.parentActivityCalendarCodeSick),
        _CodeLegendItem(code: 'ОТ', label: l10n.parentActivityCalendarCodeExcused),
        _CodeLegendItem(code: 'ТА', label: l10n.parentActivityCalendarCodeAdvanceNotice),
        if (page.scheduleLabel != null && page.scheduleLabel!.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            page.scheduleLabel!.replaceAll('\n', ' · '),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: ParentColors.inkMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _MonthNav extends StatelessWidget {
  const _MonthNav({
    required this.title,
    required this.onPrev,
    required this.onNext,
    required this.prevLabel,
    required this.nextLabel,
  });

  final String title;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final String prevLabel;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MonthButton(
          icon: Icons.chevron_left_rounded,
          label: prevLabel,
          onTap: onPrev,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: ParentColors.ink,
            ),
          ),
        ),
        _MonthButton(
          icon: Icons.chevron_right_rounded,
          label: nextLabel,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ParentColors.line),
              color: enabled ? ParentColors.surface : ParentColors.surface.withValues(alpha: 0.6),
            ),
            child: Icon(
              icon,
              size: 22,
              color: enabled ? ParentColors.ink : ParentColors.inkMuted.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: ParentColors.inkMuted,
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({required this.cell});

  final ParentAttendanceCalendarCell cell;

  @override
  Widget build(BuildContext context) {
    final colors = attendanceCalendarCellColors(cell.tone);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${cell.day}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.secondaryText,
              ),
            ),
            if (cell.attendanceCode != null && cell.attendanceCode!.isNotEmpty)
              Text(
                cell.attendanceCode!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.primaryText,
                  height: 1,
                ),
              )
            else
              const SizedBox(height: 13),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: ParentColors.line),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ParentColors.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _CodeLegendItem extends StatelessWidget {
  const _CodeLegendItem({required this.code, required this.label});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              code,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: ParentColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ParentColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
