class MobileConfig {
  const MobileConfig({
    required this.cities,
    required this.turnstilePageUrl,
    required this.turnstileRequired,
    required this.turnstileSiteKey,
  });

  factory MobileConfig.fromJson(Map<String, dynamic> json) {
    final citiesRaw = json['cities'];
    return MobileConfig(
      cities: citiesRaw is List
          ? citiesRaw.whereType<String>().toList(growable: false)
          : const [],
      turnstilePageUrl: json['turnstilePageUrl'] as String? ?? '',
      turnstileRequired: json['turnstileRequired'] == true,
      turnstileSiteKey: json['turnstileSiteKey'] as String? ?? '',
    );
  }

  static const fallback = MobileConfig(
    cities: ['Москва'],
    turnstilePageUrl: '',
    turnstileRequired: false,
    turnstileSiteKey: '',
  );

  final List<String> cities;
  final String turnstilePageUrl;
  final bool turnstileRequired;
  final String turnstileSiteKey;
}
