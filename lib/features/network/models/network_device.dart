enum NetworkDeviceKind {
  tablet,
  laptop,
  phone,
}

NetworkDeviceKind networkDeviceKindFromString(String? value) {
  switch (value) {
    case 'laptop':
      return NetworkDeviceKind.laptop;
    case 'phone':
      return NetworkDeviceKind.phone;
    case 'tablet':
    default:
      return NetworkDeviceKind.tablet;
  }
}

String networkDeviceKindToApiValue(NetworkDeviceKind kind) {
  switch (kind) {
    case NetworkDeviceKind.laptop:
      return 'laptop';
    case NetworkDeviceKind.phone:
      return 'phone';
    case NetworkDeviceKind.tablet:
      return 'tablet';
  }
}

class NetworkDevice {
  const NetworkDevice({
    required this.id,
    required this.kind,
    required this.isOnline,
    this.centerId,
    this.centerName,
    this.classroomId,
    this.classroomTitle,
    this.enrolledAt,
    this.lastSeenAt,
    this.slotLabel,
  });

  factory NetworkDevice.fromJson(Map<String, dynamic> json) {
    return NetworkDevice(
      id: json['id'] as String,
      kind: networkDeviceKindFromString(json['kind'] as String?),
      isOnline: json['isOnline'] as bool? ?? false,
      centerId: json['centerId'] as String?,
      centerName: json['centerName'] as String?,
      classroomId: json['classroomId'] as String?,
      classroomTitle: json['classroomTitle'] as String?,
      enrolledAt: json['enrolledAt'] as String?,
      lastSeenAt: json['lastSeenAt'] as String?,
      slotLabel: json['slotLabel'] as String?,
    );
  }

  final String id;
  final NetworkDeviceKind kind;
  final bool isOnline;
  final String? centerId;
  final String? centerName;
  final String? classroomId;
  final String? classroomTitle;
  final String? enrolledAt;
  final String? lastSeenAt;
  final String? slotLabel;
}
