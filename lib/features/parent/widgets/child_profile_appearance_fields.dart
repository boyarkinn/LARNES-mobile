import 'package:flutter/material.dart';

import 'package:larnes_mobile/app/theme/parent_theme.dart';

import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';

import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/features/parent/widgets/child_gender_silhouette.dart';

class ChildProfileAppearanceFields extends StatelessWidget {

  const ChildProfileAppearanceFields({

    super.key,

    required this.cardColor,

    required this.onCardColorChanged,

  });



  final ChildCardColor cardColor;

  final ValueChanged<ChildCardColor> onCardColorChanged;



  @override

  Widget build(BuildContext context) {

    final l10n = context.l10n;



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

      ],

    );

  }

}



class ChildCardColorRing extends StatelessWidget {

  const ChildCardColorRing({

    super.key,

    required this.tokens,

    this.gender,

    this.size = ParentChildCardMetrics.avatarRingSize,

  });



  final ChildCardColorTokens tokens;

  final String? gender;

  final double size;



  @override

  Widget build(BuildContext context) {

    final iconSize = size * 0.46;

    return Container(

      width: size,

      height: size,

      alignment: Alignment.center,

      decoration: BoxDecoration(

        shape: BoxShape.circle,

        color: tokens.soft,

        border: Border.all(color: ParentColors.surface, width: 3),

        boxShadow: [

          BoxShadow(

            color: tokens.tag,

            spreadRadius: 2,

          ),

          BoxShadow(

            color: tokens.tagDeep,

            offset: const Offset(0, 4),

          ),

        ],

      ),

      child: gender == null

          ? null

          : ChildGenderSilhouette(

              gender: gender!,

              color: tokens.tag,

              size: iconSize,

            ),

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


