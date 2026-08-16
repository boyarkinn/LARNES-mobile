import 'package:flutter/material.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class KioskUnplacedScreen extends StatelessWidget {
  const KioskUnplacedScreen({
    super.key,
    required this.onOpenSettings,
  });

  final VoidCallback onOpenSettings;

  static const _amberSurface = Color(0xFFFFFBEB);
  static const _amberBorder = Color(0xFFFDE68A);
  static const _amberText = Color(0xFF451A03);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _amberSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _amberBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.kioskUnplacedTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.kioskUnplacedSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _amberText,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: onOpenSettings,
                  child: Text(l10n.kioskUnplacedSettings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
