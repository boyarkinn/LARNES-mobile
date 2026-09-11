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
    this.liveError = false,
    this.liveLabel,
    this.livePulse = false,
    this.onLongPress,
  });

  final ParentChild child;
  final bool liveError;
  final String? liveLabel;
  final bool livePulse;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

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
    final showFooter = age != null || liveLabel != null;

    return ParentScaleTap(
      onTap: onTap,
      onLongPress: onLongPress,
      child: _LiveCallShell(
        active: livePulse && !liveError,
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
                        if (showFooter) ...[
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: ParentChildCardMetrics.footerTopPadding,
                            ),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (age != null)
                                  _AgePill(
                                    label: formatChildAgeYears(age, locale).toUpperCase(),
                                    tokens: tokens,
                                  ),
                                if (liveLabel != null)
                                  _LiveLessonPill(
                                    error: liveError,
                                    label: liveLabel!,
                                    sentenceCase: livePulse || liveError,
                                  ),
                              ],
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
      ),
    );
  }
}

class _LiveCallShell extends StatefulWidget {
  const _LiveCallShell({
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<_LiveCallShell> createState() => _LiveCallShellState();
}

class _LiveCallShellState extends State<_LiveCallShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _LiveCallShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (!widget.active || reduceMotion) {
      return DecoratedBox(
        decoration: widget.active
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(ParentRadii.card),
                border: Border.all(color: ParentColors.shell, width: 3),
              )
            : const BoxDecoration(),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ParentRadii.card),
            border: Border.all(color: ParentColors.shell, width: 2 + t * 1.5),
            boxShadow: [
              BoxShadow(
                color: ParentColors.shell.withValues(alpha: 0.22 + t * 0.28),
                blurRadius: 10 + t * 18,
                spreadRadius: 1 + t * 3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _LiveLessonPill extends StatelessWidget {
  const _LiveLessonPill({
    required this.error,
    required this.label,
    required this.sentenceCase,
  });

  final bool error;
  final String label;
  final bool sentenceCase;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: error ? const Color(0xFFC0392B) : ParentColors.shell,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: error ? const Color(0xFF8E2A20) : ParentColors.shellDeep,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        child: Text(
          sentenceCase ? label : label.toUpperCase(),
          style: GoogleFonts.onest(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: sentenceCase ? 0.01 * 12 : 0.03 * 12,
            color: Colors.white,
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
