import 'package:larnes_mobile/core/api/api_error_body.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

/// Совпадает с [FAMILY_SETUP_REQUIRED_CODE] на platform.
const kFamilySetupRequiredCode = 'family_setup_required';

Map<String, dynamic>? parentPanelErrorMap(dynamic body) => parseApiJsonBody(body);

String parentPanelErrorMessage(
  dynamic body,
  AppLocalizations l10n, {
  String? fallback,
}) =>
    apiMessageFromBody(body, l10n, fallback: fallback);

String? parentPanelErrorCode(dynamic body) {
  final code = parentPanelErrorMap(body)?['code'];
  return code is String && code.isNotEmpty ? code : null;
}

bool isFamilySetupRequiredCode(String? code) => code == kFamilySetupRequiredCode;
