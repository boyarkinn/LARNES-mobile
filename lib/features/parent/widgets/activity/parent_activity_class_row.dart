import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';

/// Строка класса L2 — web `.parent-activity-detail-row`.
class ParentActivityClassRow extends StatelessWidget {
  const ParentActivityClassRow({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ParentActivityClass item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: item.isActive ? 1 : 0.78,
      child: Material(
        color: ParentColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ParentColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.placeLabel,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ParentColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '«${item.groupName}»',
                        style: textTheme.bodySmall?.copyWith(
                          color: ParentColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: ParentColors.inkMuted.withValues(alpha: 0.72),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
