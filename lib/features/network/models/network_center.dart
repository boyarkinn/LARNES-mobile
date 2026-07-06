class NetworkCenter {
  const NetworkCenter({
    required this.id,
    required this.name,
    required this.ownerUserId,
    required this.createdAt,
    this.city,
    this.directions = const [],
  });

  factory NetworkCenter.fromJson(Map<String, dynamic> json) {
    final rawDirections = json['directions'];
    return NetworkCenter(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerUserId: json['ownerUserId'] as String,
      createdAt: json['createdAt'] as String,
      city: json['city'] as String?,
      directions: rawDirections is List
          ? rawDirections.map((item) => item.toString()).toList(growable: false)
          : const [],
    );
  }

  final String id;
  final String name;
  final String ownerUserId;
  final String createdAt;
  final String? city;
  final List<String> directions;
}
