import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

/// L3 начисление — web `.parent-payment-accrual-table`.
class ParentPaymentAccrualTable extends StatelessWidget {
  const ParentPaymentAccrualTable({
    super.key,
    required this.detail,
    required this.l10n,
  });

  final ParentActivityAccrualDetailPage detail;
  final AppLocalizations l10n;

  static const _tableMinWidth = 520.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: ParentColors.ink,
              height: 1.45,
            ),
            children: [
              TextSpan(
                text: detail.totalLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ParentColors.shell,
                ),
              ),
              TextSpan(text: ' ${l10n.parentActivityPaymentAccrualHeadSuffix}'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: ParentColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ParentColors.line),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: _tableMinWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TableHead(l10n: l10n),
                    for (var index = 0; index < detail.rows.length; index++)
                      _TableRow(
                        row: detail.rows[index],
                        showDivider: index > 0,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TableHead extends StatelessWidget {
  const _TableHead({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: ParentColors.parchmentDeep),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: ParentColors.inkMuted,
          ),
          child: Row(
            children: [
              SizedBox(width: 68, child: Text(l10n.parentActivityPaymentAccrualColAmount.toUpperCase())),
              SizedBox(width: 46, child: Text(l10n.parentActivityPaymentAccrualColDate.toUpperCase())),
              SizedBox(width: 78, child: Text(l10n.parentActivityPaymentAccrualColTime.toUpperCase())),
              Expanded(child: Text(l10n.parentActivityPaymentAccrualColCenter.toUpperCase())),
              SizedBox(width: 36, child: Text(l10n.parentActivityPaymentAccrualColClass.toUpperCase())),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.row,
    required this.showDivider,
  });

  final ParentActivityAccrualDetailRow row;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      height: 1.25,
      color: ParentColors.ink,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(top: BorderSide(color: ParentColors.line.withValues(alpha: 0.55)))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 68,
              child: Text(row.amountLabel, style: textStyle?.copyWith(fontWeight: FontWeight.w600)),
            ),
            SizedBox(width: 46, child: Text(row.dateLabel, style: textStyle)),
            SizedBox(width: 78, child: Text(row.timeLabel, style: textStyle)),
            Expanded(child: Text(row.centerName, style: textStyle)),
            SizedBox(width: 36, child: Text(row.classroomLabel, style: textStyle)),
          ],
        ),
      ),
    );
  }
}
