class MobileConfig {
  const MobileConfig({required this.cities});

  factory MobileConfig.fromJson(Map<String, dynamic> json) {
    final citiesRaw = json['cities'];
    return MobileConfig(
      cities: citiesRaw is List
          ? citiesRaw.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  static const fallback = MobileConfig(cities: ['Москва']);

  final List<String> cities;
}
