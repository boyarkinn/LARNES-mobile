class NetworkClassroom {
  const NetworkClassroom({
    required this.id,
    required this.centerId,
    required this.centerName,
    required this.title,
  });

  factory NetworkClassroom.fromJson(Map<String, dynamic> json) {
    return NetworkClassroom(
      id: json['id'] as String,
      centerId: json['centerId'] as String,
      centerName: json['centerName'] as String,
      title: json['title'] as String,
    );
  }

  final String id;
  final String centerId;
  final String centerName;
  final String title;
}
