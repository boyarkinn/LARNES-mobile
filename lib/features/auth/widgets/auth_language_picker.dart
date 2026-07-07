import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Instagram-style language trigger for auth screens: plain text + bottom sheet.
class AuthLanguageFooterLink extends StatelessWidget {
  const AuthLanguageFooterLink({super.key});

  static String languageName(BuildContext context, String code) {
    final l10n = context.l10n;
    return code == 'en' ? l10n.languageEn : l10n.languageRu;
  }

  static Future<void> showSheet(BuildContext context) async {
    final controller = LocaleScope.of(context);
    final l10n = context.l10n;
    final current = controller.localeCode;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ParentColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ParentRadii.card)),
      ),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                  child: Text(
                    l10n.languageLabel,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ParentColors.ink,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(ParentRadii.card),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: ParentColors.line),
                      borderRadius: BorderRadius.circular(ParentRadii.card),
                    ),
                    child: Column(
                      children: [
                        _AuthLanguageSheetOption(
                          label: l10n.languageRu,
                          selected: current == 'ru',
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            await controller.setLocale(const Locale('ru'));
                          },
                        ),
                        const AccountDivider(),
                        _AuthLanguageSheetOption(
                          label: l10n.languageEn,
                          selected: current == 'en',
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            await controller.setLocale(const Locale('en'));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.of(context);
    final label = languageName(context, controller.localeCode);

    return Semantics(
      button: true,
      label: context.l10n.languageLabel,
      child: GestureDetector(
        onTap: () => showSheet(context),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.onest(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ParentColors.inkMuted,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: ParentColors.inkMuted.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthLanguageSheetOption extends StatelessWidget {
  const _AuthLanguageSheetOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ParentScaleTap(
      onTap: onTap,
      child: ColoredBox(
        color: selected ? ParentColors.shellSoft : Colors.transparent,
        child: Padding(
          padding: AccountDeskMetrics.rowPadding,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.onest(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? ParentColors.shellDeep : ParentColors.ink,
                  ),
                ),
              ),
              if (selected)
                Text(
                  '✓',
                  style: GoogleFonts.onest(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ParentColors.shell,
                    height: 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
