import 'package:flutter_test/flutter_test.dart';

import 'memory_device_token_storage.dart';

void main() {
  group('DeviceTokenStorage (memory)', () {
    late MemoryDeviceTokenStorage storage;

    setUp(() {
      storage = MemoryDeviceTokenStorage();
    });

    test('starts empty', () async {
      expect(await storage.hasToken(), isFalse);
      expect(await storage.readToken(), isNull);
    });

    test('persists token round-trip', () async {
      await storage.writeToken('device-jwt-token');

      expect(await storage.hasToken(), isTrue);
      expect(await storage.readToken(), 'device-jwt-token');
    });

    test('clearToken removes stored value', () async {
      await storage.writeToken('device-jwt-token');
      await storage.clearToken();

      expect(await storage.hasToken(), isFalse);
      expect(await storage.readToken(), isNull);
    });
  });
}
