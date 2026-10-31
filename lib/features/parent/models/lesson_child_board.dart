class LessonChildBoard {
  const LessonChildBoard({
    this.conversation,
    required this.drawMode,
    required this.exercises,
    required this.focusRoomId,
    required this.lessonSessionId,
    required this.roomEpoch,
    required this.scene,
    required this.sceneRevision,
    this.serverNow = 0,
    this.presence = const [],
    this.navigation = const [],
    this.sceneGeneration = 0,
    this.participants = const [],
    this.personalRuns = const [],
    this.rulerScale,
    required this.sound,
    required this.title,
  });

  final String drawMode;
  final Map<String, dynamic>? conversation;
  final List<Map<String, dynamic>> exercises;
  final String focusRoomId;
  final String lessonSessionId;
  final int roomEpoch;
  final List<dynamic> scene;
  final int sceneRevision;
  final int serverNow;
  final List<dynamic> presence;
  final List<dynamic> navigation;
  final int sceneGeneration;
  final List<dynamic> participants;
  final List<dynamic> personalRuns;
  final num? rulerScale;
  final String sound;
  final String title;

  static LessonChildBoard? fromJson(Map<String, dynamic>? json) {
    if (json == null || json['status'] != 'ok') {
      return null;
    }
    final session = json['lessonSessionId'];
    final focus = json['focusRoomId'];
    if (session is! String ||
        session.isEmpty ||
        focus is! String ||
        focus.isEmpty) {
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
    final conversation = json['conversation'];
    return LessonChildBoard(
      conversation:
          conversation is Map &&
              (conversation['mode'] == 'listening' ||
                  conversation['mode'] == 'talking') &&
              conversation['remainingMs'] is int &&
              (conversation['remainingMs'] as int) > 0
          ? {
              'mode': conversation['mode'],
              'remainingMs': (conversation['remainingMs'] as int).clamp(
                0,
                10000,
              ),
            }
          : null,
      drawMode: json['drawMode'] == 'all' ? 'all' : 'teacher',
      exercises: exercises,
      focusRoomId: focus,
      lessonSessionId: session,
      roomEpoch: epoch is int ? epoch : 0,
      scene: scene is List ? scene : const [],
      sceneRevision: revision is int ? revision : 0,
      serverNow: json['serverNow'] is int ? json['serverNow'] as int : 0,
      presence: json['presence'] is List ? json['presence'] as List : const [],
      navigation: json['navigation'] is List
          ? json['navigation'] as List
          : const [],
      sceneGeneration: json['sceneGeneration'] is int
          ? json['sceneGeneration'] as int
          : 0,
      personalRuns: json['personalRuns'] is List
          ? json['personalRuns'] as List
          : const [],
      participants: json['participants'] is List
          ? json['participants'] as List
          : const [],
      rulerScale: json['rulerScale'] is num ? json['rulerScale'] as num : null,
      sound: json['sound'] is String ? json['sound'] as String : 'main',
      title: json['title'] is String ? json['title'] as String : '',
    );
  }

  String get instanceKey => exercises
      .map((item) {
        final resources = item['resources'];
        final fence = resources is Map ? resources['fence'] : '';
        return '${item['instanceId']}:${item['instanceGeneration']}:${item['revision']}:${item['stepIndex']}:$fence';
      })
      .join(',');
}
