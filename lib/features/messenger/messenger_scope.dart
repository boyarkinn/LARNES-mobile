import 'dart:math';

import 'package:larnes_mobile/core/auth/child_session_token_storage.dart';
import 'package:larnes_mobile/core/auth/lesson_guest_key_storage.dart';
import 'package:larnes_mobile/core/auth/token_storage.dart';

const messengerGuestHeader = 'X-Larnes-Lesson-Guest-Key';
const messengerTailCursor = '999999999999999';

enum MessengerCredential { account, guest, kiosk }

enum MessengerIntent { child, self }

/// Who is asking. The server still chooses the author of each message.
class MessengerScope {
  const MessengerScope({
    required this.authorization,
    required this.credential,
    required this.intent,
    required this.lessonSessionId,
    required this.ownerKey,
    this.admissionId,
    this.childId,
  });

  factory MessengerScope.parent({
    required String accountId,
    required String childId,
    required String lessonSessionId,
    TokenStorage? tokens,
    MessengerIntent intent = MessengerIntent.self,
  }) {
    final storage = tokens ?? TokenStorage();
    return MessengerScope(
      credential: MessengerCredential.account,
      intent: intent,
      lessonSessionId: lessonSessionId,
      ownerKey: accountId,
      childId: childId,
      authorization: () => _bearer(storage.readToken),
    );
  }

  factory MessengerScope.guest({
    required String lessonSessionId,
    String? admissionId,
    String? childId,
    LessonGuestKeyStorage? keys,
  }) {
    final storage = keys ?? LessonGuestKeyStorage();
    return MessengerScope(
      credential: MessengerCredential.guest,
      intent: MessengerIntent.self,
      lessonSessionId: lessonSessionId,
      ownerKey: 'guest:${admissionId ?? lessonSessionId}',
      admissionId: admissionId,
      childId: childId,
      authorization: () async {
        final key = await storage.readKey();
        if (key == null || key.isEmpty) return const {};
        return {messengerGuestHeader: key};
      },
    );
  }

  factory MessengerScope.kiosk({
    required String childId,
    required String deviceId,
    required String lessonSessionId,
    ChildSessionTokenStorage? tokens,
  }) {
    final storage = tokens ?? ChildSessionTokenStorage();
    return MessengerScope(
      credential: MessengerCredential.kiosk,
      intent: MessengerIntent.child,
      lessonSessionId: lessonSessionId,
      ownerKey: 'kiosk:$deviceId',
      admissionId: deviceId,
      childId: childId,
      authorization: () => _bearer(storage.readToken),
    );
  }

  final Future<Map<String, String>> Function() authorization;
  final MessengerCredential credential;
  final MessengerIntent intent;
  final String lessonSessionId;
  final String ownerKey;
  final String? admissionId;
  final String? childId;

  bool get canOpen => lessonSessionId.trim().isNotEmpty;

  String get sessionKey => [
    ownerKey,
    lessonSessionId,
    credential.name,
    intent.name,
    childId ?? '',
    admissionId ?? '',
  ].join('\n');

  MessengerScope forLesson(String lessonSessionId) {
    return MessengerScope(
      authorization: authorization,
      credential: credential,
      intent: intent,
      lessonSessionId: lessonSessionId,
      ownerKey: ownerKey,
      admissionId: admissionId,
      childId: childId,
    );
  }

  /// Query sent to the lesson route. The guest key is a header, never a parameter.
  Map<String, String> query({String? after, String? before, String? view}) {
    return {
      'intent': intent.name,
      'credential': credential.name,
      'view': ?view,
      if (childId != null && childId!.isNotEmpty) 'childId': childId!,
      'after': ?after,
      'before': ?before,
    };
  }
}

Future<Map<String, String>> _bearer(Future<String?> Function() read) async {
  final token = await read();
  if (token == null || token.isEmpty) return const {};
  return {'Authorization': 'Bearer $token'};
}

String messengerClientKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
