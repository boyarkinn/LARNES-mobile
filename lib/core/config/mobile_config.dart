class MobileConfig {
  const MobileConfig({
    required this.childConsentPath,
    required this.childConsentVersionId,
    required this.cities,
    required this.privacyPath,
    required this.termsPath,
    required this.termsVersionId,
  });

  factory MobileConfig.fromJson(Map<String, dynamic> json) {
    final citiesRaw = json['cities'];
    final childLegal = json['childProfileLegal'];
    final legal = json['registrationLegal'];
    return MobileConfig(
      childConsentPath: childLegal is Map<String, dynamic>
          ? childLegal['consentPath'] as String? ?? ''
          : '',
      childConsentVersionId: childLegal is Map<String, dynamic>
          ? childLegal['consentVersionId'] as String? ?? ''
          : '',
      cities: citiesRaw is List
          ? citiesRaw.whereType<String>().toList(growable: false)
          : const [],
      privacyPath: legal is Map<String, dynamic>
          ? legal['privacyPath'] as String? ?? ''
          : '',
      termsPath: legal is Map<String, dynamic>
          ? legal['termsPath'] as String? ?? ''
          : '',
      termsVersionId: legal is Map<String, dynamic>
          ? legal['termsVersionId'] as String? ?? ''
          : '',
    );
  }

  static const fallback = MobileConfig(
    childConsentPath: '',
    childConsentVersionId: '',
    cities: ['Москва'],
    privacyPath: '',
    termsPath: '',
    termsVersionId: '',
  );

  final String childConsentPath;
  final String childConsentVersionId;
  final List<String> cities;
  final String privacyPath;
  final String termsPath;
  final String termsVersionId;
}
