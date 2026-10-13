// Фрагмент «Эха» привязан к тексту. Совпадает с web `echo-fragment.ts`.

import 'dart:convert';

import 'package:crypto/crypto.dart';

String normalizeEchoFragment(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

String echoFragmentAudioKey(String text) {
  final digest = sha256.convert(utf8.encode(normalizeEchoFragment(text)));
  return 'passage:echo:$digest';
}

bool isEchoFragmentAudioKey(String semanticKey) {
  return RegExp(r'^passage:echo:[a-f0-9]{64}$').hasMatch(semanticKey);
}
