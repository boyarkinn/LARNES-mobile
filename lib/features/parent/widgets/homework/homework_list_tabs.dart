import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
import 'package:larnes_mobile/features/parent/utils/homework_display.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class HomeworkListTabs extends StatelessWidget {
  const HomeworkListTabs({
    super.key,
    required this.activeTab,
    required this.counts,
    required this.onTabSelected,
  });

  final ParentHomeworkTab activeTab;
  final Map<ParentHomeworkTab, int> counts;
  final ValueChanged<ParentHomeworkTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          for (final tab in ParentHomeworkTab.values) ...[
            if (tab != ParentHomeworkTab.values.first) const SizedBox(width: 8),
            FilterChip(
              label: Text(homeworkTabLabel(l10n, tab, counts[tab] ?? 0)),
              selected: activeTab == tab,
              onSelected: (_) => onTabSelected(tab),
              selectedColor: LarnesColors.indigo.withValues(alpha: 0.15),
              checkmarkColor: LarnesColors.indigo,
              labelStyle: TextStyle(
                color: activeTab == tab ? LarnesColors.indigo : LarnesColors.textPrimary,
                fontWeight: activeTab == tab ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
              side: BorderSide(
                color: activeTab == tab ? LarnesColors.indigo : LarnesColors.border,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
