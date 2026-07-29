/// Web: `platform/src/trainers/mental-arithmetic/audio/flash-audio-tempo.ts`

const kAudioPlaybackRateMax = 4.0;

/// Не замедляем клипы — только норма и быстрее (web parity).
const kFlashAudioPlaybackRateMin = 1.0;

/// Ниже — только визуал.
const kFlashAudioMuteBelowSec = 0.7;

bool shouldPlayFlashAudio(double stepPauseSec) {
  return stepPauseSec.isFinite && stepPauseSec >= kFlashAudioMuteBelowSec;
}

/// При 1 c → 2; ≥2 c → 1×; короче → быстрее.
double flashAudioPlaybackRate(double stepPauseSec) {
  if (!stepPauseSec.isFinite || stepPauseSec <= 0) {
    return 2;
  }

  final rate = 2 / stepPauseSec;
  return rate.clamp(kFlashAudioPlaybackRateMin, kAudioPlaybackRateMax);
}
