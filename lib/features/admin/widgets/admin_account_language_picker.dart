import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_account_widgets.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AdminAccountLanguagePicker extends StatelessWidget {
  const AdminAccountLanguagePicker({super.key});

  static const _locales = ['ru', 'en'];

  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.of(context);
    final l10n = context.l10n;
    final active = controller.localeCode;

    return Column(
      children: [
        for (var i = 0; i < _locales.length; i++) ...[
          if (i > 0) const AdminAccountDivider(),
          _LanguageOption(
            label: _locales[i] == 'en' ? l10n.languageEn : l10n.languageRu,
            active: active == _locales[i],
            onTap: () => controller.setLocale(Locale(_locales[i])),
          ),
        ],
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AdminColors.accent.withValues(alpha: 0.08) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AdminAccountMetrics.rowPadding,
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Center(
                  child: active
                      ? Text(
                          '✓',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.accent,
                            height: 1,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? AdminColors.accentDeep : AdminColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
