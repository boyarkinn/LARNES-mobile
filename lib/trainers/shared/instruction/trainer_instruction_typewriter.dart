/// Web: `platform/src/trainers/shared/instruction/use-trainer-instruction-typewriter.ts`

import 'dart:async';

import 'package:larnes_mobile/trainers/audio/speech_bank.dart';

class TrainerInstructionTypewriter {
  Timer? _timer;

  void start({
    required String text,
    required int durationMs,
    required bool Function() isCurrent,
    required void Function(int length) onLength,
    String? speechKey,
  }) {
    cancel();
    final shown = publishedSpeechText(speechKey, text);
    if (shown.isEmpty) {
      return;
    }

    var length = 0;
    onLength(0);

    final characterDelayMs = durationMs / shown.length;
    _timer = Timer.periodic(
      Duration(milliseconds: characterDelayMs.round().clamp(1, 1000000)),
      (_) {
        if (!isCurrent()) {
          return;
        }

        if (length >= shown.length) {
          cancel();
          return;
        }

        length += 1;
        onLength(length);
      },
    );
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
