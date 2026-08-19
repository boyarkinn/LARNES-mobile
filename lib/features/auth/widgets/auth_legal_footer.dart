import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/core/config/app_config.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:share_plus/share_plus.dart';

class AuthLegalFooter extends StatelessWidget {
  const AuthLegalFooter({super.key});

  Future<void> _openLegal(BuildContext context) async {
    final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'ru';
    await SharePlus.instance.share(
      ShareParams(text: '$base/$locale/legal'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Center(
        child: Semantics(
          button: true,
          label: context.l10n.authLegalLink,
          child: GestureDetector(
            onTap: () => _openLegal(context),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                context.l10n.authLegalLink,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AuthColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
