import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/resolve_step_audio.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_passage_play.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_passage_text.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';

const readingPaceTrackInstructionText = 'Читай в ритме';
const readingPaceTrackUnavailable = 'Эта дорожка ещё не опубликована';
const readingPaceTrackValues = ['metronome', 'zhinkin', 'rhythmic', 'countdown'];
const _countdownAmounts = [3, 2, 1];

String readingPaceTrackOf(Map<String, dynamic> params) {
  final payload = readTrainerRuntimeSnapshot('reading-pace-track', params);
  final track = (payload?['track'] ?? params['track'])?.toString();
  if (track == 'zhinkin' || track == 'rhythmic' || track == 'countdown') return track!;
  return 'metronome';
}

String? validateReadingPaceTrackRaw(Map<String, dynamic> raw) {
  final passageError = validatePassageAssignment(raw);
  if (passageError != null) return passageError;
  final track = raw['track']?.toString() ?? 'metronome';
  if (!readingPaceTrackValues.contains(track)) return 'Выберите дорожку.';
  return null;
}

class ReadingPaceTrackTrainer extends StatelessWidget {
  const ReadingPaceTrackTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final payload = readTrainerRuntimeSnapshot('reading-pace-track', params);
    final play = passagePlayFromSnapshot(payload) ?? passagePlayFromParams(params);
    final track = readingPaceTrackOf(params);

    return ReadingPassagePlay(
      beforeFade: track == 'countdown' ? _playCountdown : null,
      clickOnLetter: track == 'metronome',
      instruction: readingPaceTrackInstructionText,
      trainerKey: 'reading-pace-track',
      letterCount: play.letterCount,
      letterPauseMs: play.letterPauseMs,
      note: track == 'zhinkin' || track == 'rhythmic' ? readingPaceTrackUnavailable : null,
      onComplete: onComplete,
      resetToken: '${play.text}|${play.letterPauseMs}|$track',
      scene: (hiddenOrder) => ReadingPassageText(
        hiddenOrder: hiddenOrder,
        units: play.units,
      ),
    );
  }
}

Future<void> _playCountdown() {
  final assets = [
    for (final amount in _countdownAmounts)
      if (getAmountAudioAsset(amount) case final String asset) asset,
  ];
  return getSharedClipPlayer().play(assets, playbackRate: 1);
}
