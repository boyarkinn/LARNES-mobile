class EnrollDeviceResult {
  const EnrollDeviceResult({
    required this.deviceId,
    required this.deviceToken,
  });

  factory EnrollDeviceResult.fromJson(Map<String, dynamic> json) {
    return EnrollDeviceResult(
      deviceId: json['deviceId'] as String,
      deviceToken: json['deviceToken'] as String,
    );
  }

  final String deviceId;
  final String deviceToken;
}
