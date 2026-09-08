import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/app_update/app_update_info.dart';

void main() {
  group('AppUpdateInfo.fromJson', () {
    test('parses update payload', () {
      final info = AppUpdateInfo.fromJson({
        'versionCode': 42,
        'versionName': '1.2.0',
        'url': 'https://example.test/app.apk',
        'sha256': 'abc',
        'releaseNotes': 'Fixes',
      });

      expect(info.versionCode, 42);
      expect(info.versionName, '1.2.0');
      expect(info.url, 'https://example.test/app.apk');
      expect(info.sha256, 'abc');
      expect(info.releaseNotes, 'Fixes');
    });
  });

  group('isRemoteAppUpdateNewer', () {
    test('returns true only when remote versionCode is higher', () {
      const remote = AppUpdateInfo(
        releaseNotes: null,
        sha256: 'abc',
        url: 'https://example.test/app.apk',
        versionCode: 5,
        versionName: '1.0.0',
      );

      expect(isRemoteAppUpdateNewer(remote: remote, localVersionCode: 4), isTrue);
      expect(isRemoteAppUpdateNewer(remote: remote, localVersionCode: 5), isFalse);
      expect(isRemoteAppUpdateNewer(remote: remote, localVersionCode: 6), isFalse);
    });
  });
}
