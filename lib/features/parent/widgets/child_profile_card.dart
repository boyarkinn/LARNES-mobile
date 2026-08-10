import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/utils/child_display.dart';
import 'package:larnes_mobile/features/parent/widgets/child_profile_appearance_fields.dart';

/// Name-tag карточка ребёнка на picker (Morning Desk v4).
/// Эталон: platform/src/components/parent/child-profile-card.tsx
class ChildProfileCard extends StatelessWidget {
  const ChildProfileCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  final ParentChild child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context).localeCode;
    final names = childDisplayNameLines(child);
    final age = child.ageYears;
    final tokens = childCardColorTokens(child.cardColor);
    final nameStyle = GoogleFonts.fredoka(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.015 * 19,
      height: 1.1,
      color: ParentColors.ink,
    );

    return ParentScaleTap(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ParentRadii.card),
        child: Container(
          width: double.infinity,
          height: ParentChildCardMetrics.pickerListCardHeight,
          decoration: parentCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ColorBand(color: tokens.tag),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -ParentChildCardMetrics.innerOverlap),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ParentChildCardMetrics.innerHorizontalPadding,
                      0,
                      ParentChildCardMetrics.innerHorizontalPadding,
                      ParentChildCardMetrics.innerBottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ChildCardColorRing(
                              tokens: tokens,
                              gender: child.gender,
                            ),
                            const SizedBox(width: ParentChildCardMetrics.rowGap),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: ParentChildCardMetrics.metaTopPadding,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (names.lastName.isNotEmpty)
                                      Text(names.lastName, style: nameStyle),
                                    if (names.givenName.isNotEmpty) ...[
                                      if (names.lastName.isNotEmpty)
                                        const SizedBox(height: ParentChildCardMetrics.nameLineGap),
                                      Text(names.givenName, style: nameStyle),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (age != null) ...[
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: ParentChildCardMetrics.footerTopPadding,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _AgePill(
                                label: formatChildAgeYears(age, locale).toUpperCase(),
                                tokens: tokens,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorBand extends StatelessWidget {
  const _ColorBand({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ParentChildCardMetrics.bandHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: color),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 4,
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

class _AgePill extends StatelessWidget {
  const _AgePill({
    required this.label,
    required this.tokens,
  });

  final String label;
  final ChildCardColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.tag,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: tokens.tagDeep,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        child: Text(
          label,
          style: GoogleFonts.onest(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.03 * 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
