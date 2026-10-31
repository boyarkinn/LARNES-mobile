import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NativeMessageSound {
  static final enabled = ValueNotifier(true);
  static AudioPlayer? _player;
  static Future<void>? _preparing;
  static int _last = 0, _epoch = 0;
  static Future<void> load() async {
    try {
      enabled.value =
          (await SharedPreferences.getInstance().timeout(
            const Duration(seconds: 1),
          )).getBool('larnes-message-sound') ??
          true;
    } catch (_) {}
  }

  static void setEnabled(bool value) {
    enabled.value = value;
    unawaited(
      SharedPreferences.getInstance()
          .then((p) => p.setBool('larnes-message-sound', value))
          .catchError((_) => false),
    );
  }

  static Future<void> prepare() => _preparing ??= () async {
    try {
      _player = AudioPlayer(
        handleAudioSessionActivation: false,
        handleInterruptions: false,
      );
      await _player!
          .setAsset('assets/sounds/larnes-message.wav')
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }();
  static void play() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!enabled.value || now - _last < 5000) return;
    _last = now;
    final epoch = _epoch;
    unawaited(() async {
      try {
        await prepare();
        if (epoch != _epoch || !enabled.value) return;
        await _player?.seek(Duration.zero);
        if (epoch == _epoch) unawaited(_player!.play().catchError((_) {}));
      } catch (_) {}
    }());
  }

  static void stop() {
    _epoch++;
    unawaited(_player?.stop().catchError((_) {}));
  }
}
