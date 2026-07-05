import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_text_theme.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';

/// Dev/preview: проверка Morning Desk tokens (фаза 1). Не в prod router.
class ParentThemePreview extends StatelessWidget {
  const ParentThemePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = buildParentTextTheme();

    return Theme(
      data: Theme.of(context).copyWith(textTheme: textTheme),
      child: ParentParchmentBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: ParentColors.surface.withValues(alpha: 0.88),
            elevation: 0,
            title: Text('Morning Desk tokens', style: textTheme.titleMedium),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Card base', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Container(
                height: 88,
                padding: const EdgeInsets.all(16),
                decoration: parentCardDecoration(),
                alignment: Alignment.centerLeft,
                child: Text('parentCardDecoration()', style: textTheme.bodyLarge),
              ),
              const SizedBox(height: 20),
              Text('Add card', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Container(
                height: 72,
                alignment: Alignment.center,
                decoration: parentAddCardDecoration(),
                child: Text(
                  '+ Add child',
                  style: textTheme.bodyLarge?.copyWith(color: ParentColors.shellDeep),
                ),
              ),
              const SizedBox(height: 20),
              Text('Child tag colors', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slug in childCardColors)
                    _TagSwatch(slug: slug, textTheme: textTheme),
                ],
              ),
              const SizedBox(height: 20),
              Text('Typography', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Text('Fredoka display', style: textTheme.headlineMedium),
              Text('Onest body', style: textTheme.bodyLarge),
              Text('Onest muted', style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagSwatch extends StatelessWidget {
  const _TagSwatch({required this.slug, required this.textTheme});

  final ChildCardColor slug;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final tokens = childCardColorTokens(slug);

    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: tokens.soft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.tag),
      ),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tokens.tag,
              shape: BoxShape.circle,
              border: Border.all(color: tokens.tagDeep, width: 2),
            ),
          ),
          const SizedBox(height: 6),
          Text(slug.name, style: textTheme.bodyMedium?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
