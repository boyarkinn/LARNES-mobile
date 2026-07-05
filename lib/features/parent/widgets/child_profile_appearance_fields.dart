import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/theme/child_avatar_catalog.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/widgets/child_avatar.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Выбор цвета карточки и персонажа (create / edit ребёнка).
class ChildProfileAppearanceFields extends StatelessWidget {
  const ChildProfileAppearanceFields({
    super.key,
    required this.cardColor,
    required this.avatarSlug,
    required this.onCardColorChanged,
    required this.onAvatarSlugChanged,
  });

  final ChildCardColor cardColor;
  final ChildAvatarSlug avatarSlug;
  final ValueChanged<ChildCardColor> onCardColorChanged;
  final ValueChanged<ChildAvatarSlug> onAvatarSlugChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final avatarSoftBackground = childCardColorTokens(cardColor).soft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SegmentLabel(text: l10n.parentChildFormCardColor),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final color in childCardColors)
              _ColorSwatch(
                color: color,
                selected: color == cardColor,
                label: _cardColorLabel(l10n, color),
                onTap: () => onCardColorChanged(color),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _SegmentLabel(text: l10n.parentChildFormAvatar),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final slug in childAvatarSlugs) ...[
              Expanded(
                child: _AvatarOption(
                  slug: slug,
                  selected: slug == avatarSlug,
                  label: _avatarLabel(l10n, slug),
                  avatarBackground: avatarSoftBackground,
                  onTap: () => onAvatarSlugChanged(slug),
                ),
              ),
              if (slug != childAvatarSlugs.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: ParentColors.inkMuted,
          ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final ChildCardColor color;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  static const _dotSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final tagColor = childCardColorTokens(color).tag;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: ParentMotion.duration,
          curve: ParentMotion.curve,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: ParentColors.surface,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: ParentColors.shell,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tagColor,
              border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.08)),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    required this.slug,
    required this.selected,
    required this.label,
    required this.avatarBackground,
    required this.onTap,
  });

  final ChildAvatarSlug slug;
  final bool selected;
  final String label;
  final Color avatarBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: ParentMotion.duration,
          curve: ParentMotion.curve,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? ParentColors.shellSoft : ParentColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? ParentColors.shell : ParentColors.line,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarBackground,
                ),
                child: ChildAvatar(slug: slug, size: 36),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ParentColors.inkMuted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _cardColorLabel(AppLocalizations l10n, ChildCardColor color) {
  return switch (color) {
    ChildCardColor.orange => l10n.parentChildFormCardColorOrange,
    ChildCardColor.emerald => l10n.parentChildFormCardColorEmerald,
    ChildCardColor.violet => l10n.parentChildFormCardColorViolet,
    ChildCardColor.sky => l10n.parentChildFormCardColorSky,
    ChildCardColor.rose => l10n.parentChildFormCardColorRose,
    ChildCardColor.amber => l10n.parentChildFormCardColorAmber,
  };
}

String _avatarLabel(AppLocalizations l10n, ChildAvatarSlug slug) {
  return switch (slug) {
    ChildAvatarSlug.fox => l10n.parentChildFormAvatarFox,
    ChildAvatarSlug.bear => l10n.parentChildFormAvatarBear,
    ChildAvatarSlug.owl => l10n.parentChildFormAvatarOwl,
  };
}
