import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

/// Pill tabs — web `.parent-payment-mode-bar`.
class ParentActivityPaymentsTabs extends StatelessWidget {
  const ParentActivityPaymentsTabs({
    super.key,
    required this.l10n,
    required this.activeTab,
    required this.onTabSelected,
  });

  final AppLocalizations l10n;
  final ParentActivityPaymentsTab activeTab;
  final ValueChanged<ParentActivityPaymentsTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: l10n.parentActivityPaymentsTabsLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ParentColors.parchmentDeep,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: l10n.parentActivityPaymentsTabAccruals,
                  active: activeTab == ParentActivityPaymentsTab.accruals,
                  onTap: () => onTabSelected(ParentActivityPaymentsTab.accruals),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _TabButton(
                  label: l10n.parentActivityPaymentsTabReceipts,
                  active: activeTab == ParentActivityPaymentsTab.receipts,
                  onTap: () => onTabSelected(ParentActivityPaymentsTab.receipts),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: active ? ParentColors.surface : Colors.transparent,
      elevation: active ? 0.5 : 0,
      shadowColor: ParentColors.shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: active ? ParentColors.ink : ParentColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
