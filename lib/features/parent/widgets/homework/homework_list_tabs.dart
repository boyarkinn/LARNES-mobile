import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
import 'package:larnes_mobile/features/parent/utils/homework_display.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Эталон: platform `.parent-filter-tab` / parent-homework-list-tabs.tsx
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
      child: Row(
        children: [
          for (final tab in ParentHomeworkTab.values) ...[
            if (tab != ParentHomeworkTab.values.first) const SizedBox(width: 8),
            _FilterTab(
              label: homeworkTabLabel(l10n, tab, counts[tab] ?? 0),
              active: activeTab == tab,
              onTap: () => onTabSelected(tab),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? ParentColors.shell : ParentColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? ParentColors.shell : ParentColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : ParentColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
