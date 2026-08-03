import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/features/parent/theme/activity_payment_colors.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class ParentActivityPaymentLegend extends StatelessWidget {
  const ParentActivityPaymentLegend({
    super.key,
    required this.l10n,
    required this.showMakeupLegend,
  });

  final AppLocalizations l10n;
  final bool showMakeupLegend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _LegendItem(
            color: activityPaymentLegendPaid,
            label: l10n.parentActivityCalendarLegendPaid,
          ),
          _LegendItem(
            color: activityPaymentLegendFirstUnpaid,
            label: l10n.parentActivityCalendarLegendFirstUnpaid,
          ),
          _LegendItem(
            color: activityPaymentLegendUnpaid,
            label: l10n.parentActivityCalendarLegendUnpaid,
          ),
          if (showMakeupLegend)
            _LegendItem(
              color: activityPaymentLegendMakeup,
              label: l10n.parentActivityCalendarLegendMakeup,
            ),
        ],
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
