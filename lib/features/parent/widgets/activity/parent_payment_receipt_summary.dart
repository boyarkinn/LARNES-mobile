import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

/// L3 чек — web `ParentActivityReceiptDetailView`.
class ParentPaymentReceiptSummary extends StatelessWidget {
  const ParentPaymentReceiptSummary({
    super.key,
    required this.detail,
    required this.l10n,
  });

  final ParentActivityReceiptDetailPage detail;
  final AppLocalizations l10n;

  static const _giftColor = Color(0xFFD97706);
  static const _refundColor = Color(0xFFC0392B);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ParentColors.shell.withValues(alpha: 0.22)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEEF3FF),
            ParentColors.surface,
          ],
          stops: const [0, 0.65],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 29, 46, 0.06),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              detail.titleLabel,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: ParentColors.shell,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail.subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: ParentColors.inkMuted,
              ),
            ),
            if (detail.isWalletWizardV2) ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: ParentColors.shell.withValues(alpha: 0.14)),
              const SizedBox(height: 12),
              _BreakdownLine(
                label: l10n.parentActivityPaymentReceiptAccepted,
                value: detail.acceptedLabel,
              ),
              if (detail.hasGift && detail.giftLabel != null)
                _BreakdownLine(
                  label: l10n.parentActivityPaymentReceiptGift,
                  value: detail.giftLabel!,
                  valueColor: _giftColor,
                ),
              if (detail.hasRefund && detail.refundLabel != null)
                _BreakdownLine(
                  label: l10n.parentActivityPaymentReceiptRefund,
                  value: detail.refundLabel!,
                  valueColor: _refundColor,
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: ParentColors.shell.withValues(alpha: 0.18),
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _BreakdownLine(
                      label: l10n.parentActivityPaymentReceiptTotalOnAccount,
                      value: detail.totalOnAccountLabel,
                      emphasized: true,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreakdownLine extends StatelessWidget {
  const _BreakdownLine({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = emphasized
        ? textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: ParentColors.ink)
        : textTheme.bodySmall?.copyWith(color: ParentColors.inkMuted);
    final valueStyle = emphasized
        ? textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: ParentColors.ink)
        : textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? ParentColors.ink,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: 12),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
