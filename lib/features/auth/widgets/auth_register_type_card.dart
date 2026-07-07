import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';

/// Tappable desk card for register account type (Morning Desk v4).
class AuthRegisterTypeCard extends StatelessWidget {
  const AuthRegisterTypeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tokens,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final ChildCardColorTokens tokens;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(ParentRadii.card),
      child: DecoratedBox(
        decoration: parentCardDecoration(),
        child: SizedBox(
          width: double.infinity,
          height: ParentChildCardMetrics.pickerListCardHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ColorBand(color: tokens.tag),
              Expanded(
                child: Padding(
                  padding: ParentStudyHubCardMetrics.innerPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _IconRing(tokens: tokens, icon: icon),
                      const SizedBox(height: ParentStudyHubCardMetrics.contentGap),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.015 * 19,
                          height: 1.2,
                          color: ParentColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.onest(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          color: ParentColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return ParentScaleTap(onTap: onTap, child: card);
  }
}

class _ColorBand extends StatelessWidget {
  const _ColorBand({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ParentStudyHubCardMetrics.bandHeight,
      child: ColoredBox(color: color),
    );
  }
}

class _IconRing extends StatelessWidget {
  const _IconRing({required this.tokens, required this.icon});

  final ChildCardColorTokens tokens;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ParentStudyHubCardMetrics.iconRingSize,
      height: ParentStudyHubCardMetrics.iconRingSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.soft,
        border: Border.all(color: tokens.tag.withValues(alpha: 0.35)),
      ),
      child: Icon(
        icon,
        size: ParentStudyHubCardMetrics.iconImageSize,
        color: tokens.tagDeep,
      ),
    );
  }
}
