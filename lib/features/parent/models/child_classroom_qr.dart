class ChildClassroomQrState {
  const ChildClassroomQrState({
    required this.active,
    this.version,
    this.qrDataUrl,
  });

  final bool active;
  final int? version;
  final String? qrDataUrl;

  factory ChildClassroomQrState.fromJson(Map<String, dynamic> json) {
    final active = json['active'] == true;
    if (!active) {
      return const ChildClassroomQrState(active: false);
    }

    return ChildClassroomQrState(
      active: true,
      version: json['version'] as int?,
      qrDataUrl: json['qrDataUrl'] as String?,
    );
  }
}

enum ChildClassroomQrAction {
  issue,
  regenerate,
  revoke,
}
