import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/config/app_config.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:share_plus/share_plus.dart';

class VoluntaryConsentPanel extends StatelessWidget {
  const VoluntaryConsentPanel({
    super.key,
    required this.accepted,
    required this.context,
    required this.onChanged,
  });

  final bool accepted;
  final VoluntaryConsentContext context;
  final ValueChanged<bool> onChanged;

  Future<void> _openConsent(BuildContext context) async {
    final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'ru';
    final versionId = this.context.versionId;
    if (versionId == null) return;
    await SharePlus.instance.share(
      ShareParams(
        text: '$base/$locale/legal/personal-data-consent'
            '?version=${Uri.encodeQueryComponent(versionId)}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final version = this.context.versionLabel;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        border: Border.all(color: const Color(0xFFBAE6FD)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.voluntaryConsentTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(l10n.voluntaryConsentParentFields),
          if (version == null || this.context.versionId == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.voluntaryConsentVersionMissing,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: accepted,
              onChanged: (value) => onChanged(value ?? false),
              title: Text(l10n.voluntaryConsentParentCheckbox),
            ),
            TextButton(
              onPressed: () => _openConsent(context),
              child: Text(l10n.voluntaryConsentOpenVersion(version)),
            ),
          ],
        ],
      ),
    );
  }
}
