import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/models/parent_reward.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class RewardShopDetailBody extends StatelessWidget {
  const RewardShopDetailBody({
    super.key,
    required this.detail,
    required this.isClaiming,
    required this.onClaim,
    this.error,
    this.notice,
  });

  final ParentRewardShopDetail detail;
  final String? error;
  final bool isClaiming;
  final String? notice;
  final ValueChanged<String> onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text(
          l10n.parentRewardsBalance(detail.balancePoints),
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.015 * 20,
            color: ParentColors.ink,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFC91D38))),
        ],
        if (notice != null) ...[
          const SizedBox(height: 12),
          Text(notice!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ParentColors.shellDeep)),
        ],
        const SizedBox(height: 20),
        if (detail.items.isEmpty)
          Text(
            l10n.parentRewardsEmptyItems,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: ParentColors.inkMuted),
          )
        else
          for (final item in detail.items) ...[
            _RewardItemCard(
              item: item,
              isClaiming: isClaiming,
              onClaim: onClaim,
            ),
            const SizedBox(height: 16),
          ],
        if (detail.claims.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.parentRewardsClaimsTitle,
            style: GoogleFonts.fredoka(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: ParentColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          for (final claim in detail.claims)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(claim.itemTitle, style: Theme.of(context).textTheme.bodyLarge),
                  ),
                  Text(
                    rewardClaimStatusLabel(l10n, claim.status),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

String rewardClaimStatusLabel(AppLocalizations l10n, ParentRewardClaimStatus status) {
  return switch (status) {
    ParentRewardClaimStatus.pending => l10n.parentRewardsPending,
    ParentRewardClaimStatus.handedOver => l10n.parentRewardsHandedOver,
    ParentRewardClaimStatus.cancelled => l10n.parentRewardsCancelled,
  };
}

class _RewardItemCard extends StatelessWidget {
  const _RewardItemCard({
    required this.item,
    required this.isClaiming,
    required this.onClaim,
  });

  final ParentRewardItem item;
  final bool isClaiming;
  final ValueChanged<String> onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: parentCardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ParentRadii.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: ParentColors.parchmentDeep,
                child: item.imageUrl == null
                    ? Center(
                        child: Text(
                          l10n.parentRewardsNoPhoto,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            l10n.parentRewardsNoPhoto,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.fredoka(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: ParentColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.costPoints} ${l10n.parentRewardsCost}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  if (item.canClaim)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: ParentColors.shell,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: isClaiming ? null : () => onClaim(item.id),
                      child: Text(isClaiming ? l10n.parentRewardsGetting : l10n.parentRewardsGet),
                    )
                  else
                    Text(
                      l10n.parentRewardsNotEnough,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
