import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/models/child_classroom_qr.dart';
import 'package:larnes_mobile/features/parent/widgets/account/child_classroom_qr_card.dart';

void main() {
  group('ChildClassroomQrState', () {
    test('fromJson active state', () {
      const state = ChildClassroomQrState(
        active: true,
        version: 2,
        qrDataUrl: 'data:image/png;base64,abc',
      );
      final parsed = ChildClassroomQrState.fromJson({
        'active': true,
        'version': 2,
        'qrDataUrl': 'data:image/png;base64,abc',
      });
      expect(parsed.active, state.active);
      expect(parsed.version, state.version);
      expect(parsed.qrDataUrl, state.qrDataUrl);
    });

    test('fromJson revoked state', () {
      final parsed = ChildClassroomQrState.fromJson({'active': false});
      expect(parsed.active, isFalse);
      expect(parsed.version, isNull);
      expect(parsed.qrDataUrl, isNull);
    });
  });

  group('decodeQrDataUrl', () {
    test('decodes base64 payload', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
      expect(decodeQrDataUrl(dataUrl), bytes);
    });

    test('returns null for invalid input', () {
      expect(decodeQrDataUrl('not-a-data-url'), isNull);
      expect(decodeQrDataUrl('data:image/png;base64,!!!'), isNull);
    });
  });
}
