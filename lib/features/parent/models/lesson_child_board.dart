class LessonChildBoard {
  const LessonChildBoard({
    required this.exercises,
    required this.focusRoomId,
    required this.lessonSessionId,
    required this.roomEpoch,
    required this.scene,
    required this.sceneRevision,
    required this.sound,
    required this.title,
  });

  final List<Map<String, dynamic>> exercises;
  final String focusRoomId;
  final String lessonSessionId;
  final int roomEpoch;
  final List<dynamic> scene;
  final int sceneRevision;
  final String sound;
  final String title;

  static LessonChildBoard? fromJson(Map<String, dynamic>? json) {
    if (json == null || json['status'] != 'ok') {
      return null;
    }
    final session = json['lessonSessionId'];
    final focus = json['focusRoomId'];
    if (session is! String || session.isEmpty || focus is! String || focus.isEmpty) {
      return null;
    }
    final exercises = <Map<String, dynamic>>[];
    final rawExercises = json['exercises'];
    if (rawExercises is List) {
      for (final item in rawExercises) {
        if (item is Map) {
          exercises.add(Map<String, dynamic>.from(item));
        }
      }
    }
    final scene = json['scene'];
    final revision = json['sceneRevision'];
    final epoch = json['roomEpoch'];
    return LessonChildBoard(
      exercises: exercises,
      focusRoomId: focus,
      lessonSessionId: session,
      roomEpoch: epoch is int ? epoch : 0,
      scene: scene is List ? scene : const [],
      sceneRevision: revision is int ? revision : 0,
      sound: json['sound'] is String ? json['sound'] as String : 'main',
      title: json['title'] is String ? json['title'] as String : '',
    );
  }

  String get instanceKey => exercises
      .map((item) => '${item['instanceId']}:${item['instanceGeneration']}')
      .join(',');
}
