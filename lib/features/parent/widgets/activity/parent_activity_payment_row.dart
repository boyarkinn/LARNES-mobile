import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';

/// Строка оплат L2 — web `.parent-activity-payment-row`.
class ParentActivityPaymentRow extends StatelessWidget {
  const ParentActivityPaymentRow({
    super.key,
    required this.dateLabel,
    required this.amountLabel,
    required this.placeLabel,
    required this.onTap,
  });

  final String dateLabel;
  final String amountLabel;
  final String placeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 68,
                child: Text(
                  dateLabel,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ParentColors.inkMuted,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      amountLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ParentColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      placeLabel,
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
    );
  }
}
