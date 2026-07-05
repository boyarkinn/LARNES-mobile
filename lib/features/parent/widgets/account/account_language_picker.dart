import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Inline language picker in account hub (web `AccountLanguagePicker`).
class AccountLanguagePicker extends StatelessWidget {
  const AccountLanguagePicker({super.key});

  static const _locales = ['ru', 'en'];

  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.of(context);
    final l10n = context.l10n;
    final active = controller.localeCode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        children: [
          for (var i = 0; i < _locales.length; i++) ...[
            if (i > 0) const AccountDivider(),
            _AccountLanguageOption(
              label: _locales[i] == 'en' ? l10n.languageEn : l10n.languageRu,
              active: active == _locales[i],
              onTap: () => controller.setLocale(Locale(_locales[i])),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountLanguageOption extends StatelessWidget {
  const _AccountLanguageOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ParentScaleTap(
      onTap: onTap,
      child: ColoredBox(
        color: active ? ParentColors.shellSoft : Colors.transparent,
        child: Padding(
          padding: AccountDeskMetrics.rowPadding,
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Center(
                  child: active
                      ? Text(
                          '✓',
                          style: GoogleFonts.onest(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ParentColors.shell,
                            height: 1,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.onest(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? ParentColors.shellDeep : ParentColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
