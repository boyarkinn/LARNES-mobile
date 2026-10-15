class LessonChildBoard {
  const LessonChildBoard({
    required this.drawMode,
    required this.exercises,
    required this.focusRoomId,
    required this.lessonSessionId,
    required this.roomEpoch,
    required this.scene,
    required this.sceneRevision,
    this.serverNow = 0,
    required this.sound,
    required this.title,
  });

  final String drawMode;
  final List<Map<String, dynamic>> exercises;
  final String focusRoomId;
  final String lessonSessionId;
  final int roomEpoch;
  final List<dynamic> scene;
  final int sceneRevision;
  final int serverNow;
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
      drawMode: json['drawMode'] == 'all' ? 'all' : 'teacher',
      exercises: exercises,
      focusRoomId: focus,
      lessonSessionId: session,
      roomEpoch: epoch is int ? epoch : 0,
      scene: scene is List ? scene : const [],
      sceneRevision: revision is int ? revision : 0,
      serverNow: json['serverNow'] is int ? json['serverNow'] as int : 0,
      sound: json['sound'] is String ? json['sound'] as String : 'main',
      title: json['title'] is String ? json['title'] as String : '',
    );
  }

  String get instanceKey => exercises.map((item) {
        final resources = item['resources'];
        final fence = resources is Map ? resources['fence'] : '';
        return '${item['instanceId']}:${item['instanceGeneration']}:${item['revision']}:${item['stepIndex']}:$fence';
      }).join(',');
}
