class AppUpdateInfo {
  const AppUpdateInfo({
    required this.releaseNotes,
    required this.sha256,
    required this.url,
    required this.versionCode,
    required this.versionName,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      releaseNotes: json['releaseNotes'] as String?,
      sha256: json['sha256'] as String? ?? '',
      url: json['url'] as String? ?? '',
      versionCode: json['versionCode'] as int? ?? 0,
      versionName: json['versionName'] as String? ?? '',
    );
  }

  final String? releaseNotes;
  final String sha256;
  final String url;
  final int versionCode;
  final String versionName;
}

bool isRemoteAppUpdateNewer({
  required AppUpdateInfo remote,
  required int localVersionCode,
}) {
  return remote.versionCode > localVersionCode;
}
