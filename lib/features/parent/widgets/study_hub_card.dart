import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/theme/hub_card_appearance.dart';
import 'package:larnes_mobile/features/parent/widgets/study_hub_card_icon.dart';

/// Hub-карточка parent-зоны (Morning Desk v4).
/// Эталон: platform/src/components/parent/study-hub-card.tsx
class StudyHubCard extends StatelessWidget {
  const StudyHubCard({
    super.key,
    required this.title,
    required this.tokens,
    required this.icon,
    this.subtitle,
    this.staticCard = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final ChildCardColorTokens tokens;
  final HubCardIconKind icon;
  final bool staticCard;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.fredoka(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.015 * 19,
      height: 1.2,
      color: ParentColors.ink,
    );

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(ParentRadii.card),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: ParentStudyHubCardMetrics.minHeight),
        decoration: parentCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ColorBand(color: tokens.tag),
            Padding(
              padding: ParentStudyHubCardMetrics.innerPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconRing(tokens: tokens, icon: icon),
                  const SizedBox(height: ParentStudyHubCardMetrics.contentGap),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: ParentColors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (staticCard || onTap == null) {
      return card;
    }

    return ParentScaleTap(
      onTap: onTap!,
      child: card,
    );
  }
}

class _ColorBand extends StatelessWidget {
  const _ColorBand({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ParentStudyHubCardMetrics.bandHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: color),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconRing extends StatelessWidget {
  const _IconRing({
    required this.tokens,
    required this.icon,
  });

  final ChildCardColorTokens tokens;
  final HubCardIconKind icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ParentStudyHubCardMetrics.iconRingSize,
      height: ParentStudyHubCardMetrics.iconRingSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.soft,
        border: Border.all(color: ParentColors.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: tokens.tag,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: tokens.tagDeep,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: StudyHubCardIcon(
        kind: icon,
        color: tokens.tagDeep,
      ),
    );
  }
}
