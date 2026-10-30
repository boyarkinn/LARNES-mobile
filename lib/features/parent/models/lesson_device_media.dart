class LessonDeviceMedia {
  const LessonDeviceMedia({
    required this.assignment,
    required this.childId,
    required this.deviceId,
    required this.lessonSessionId,
    required this.revision,
    required this.audio,
    required this.video,
    required this.receive,
    required this.phase,
    this.error,
  });
  final String assignment, childId, deviceId, lessonSessionId, phase;
  final int revision;
  final bool audio, video, receive;
  final String? error;
  bool get needed => audio || video || receive;
  static LessonDeviceMedia? fromJson(dynamic value) {
    if (value is! Map ||
        value['assignment'] is! String ||
        value['childId'] is! String ||
        value['deviceId'] is! String ||
        value['lessonSessionId'] is! String ||
        value['revision'] is! int) {
      return null;
    }
    return LessonDeviceMedia(
      assignment: value['assignment'] as String,
      childId: value['childId'] as String,
      deviceId: value['deviceId'] as String,
      lessonSessionId: value['lessonSessionId'] as String,
      revision: value['revision'] as int,
      audio: value['audio'] == true,
      video: value['video'] == true,
      receive: value['receive'] == true,
      phase: value['phase'] is String ? value['phase'] as String : 'idle',
      error: value['error'] is String ? value['error'] as String : null,
    );
  }
}
