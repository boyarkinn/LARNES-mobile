import 'package:larnes_mobile/features/parent/models/parent_homework.dart';

class ParentLiveLessonWaiting {
  const ParentLiveLessonWaiting({
    required this.childName,
    required this.lessonTitle,
    this.timeLabel,
  });

  factory ParentLiveLessonWaiting.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ParentLiveLessonWaiting(childName: '', lessonTitle: '');
    }

    final time = json['timeLabel'];
    return ParentLiveLessonWaiting(
      childName: json['childName'] as String? ?? '',
      lessonTitle: json['lessonTitle'] as String? ?? '',
      timeLabel: time is String && time.isNotEmpty ? time : null,
    );
  }

  final String childName;
  final String lessonTitle;
  final String? timeLabel;
}

class ParentLiveLessonRoomState {
  const ParentLiveLessonRoomState({
    required this.status,
    this.admissionId,
    this.childId,
    this.commandSeq = 0,
    this.pendingCommand,
    this.sessionId,
    this.workspaceFormat = 'classic',
    this.waiting = const ParentLiveLessonWaiting(childName: '', lessonTitle: ''),
    this.snapshot,
  });

  factory ParentLiveLessonRoomState.fromJson(Map<String, dynamic> json) {
    final snapshot = json['snapshot'];
    return ParentLiveLessonRoomState(
      status: json['status'] as String? ?? 'error',
      admissionId: json['admissionId'] as String?,
      childId: json['childId'] as String?,
      commandSeq: (json['commandSeq'] as num?)?.toInt() ?? 0,
      sessionId: json['sessionId'] as String?,
      workspaceFormat: json['workspaceFormat'] == 'board' ? 'board' : 'classic',
      pendingCommand: json['pendingCommand'] as String?,
      waiting: ParentLiveLessonWaiting.fromJson(
        json['waiting'] is Map ? Map<String, dynamic>.from(json['waiting'] as Map) : null,
      ),
      snapshot: snapshot is Map
          ? ParentHomeworkPlaySnapshot.fromJson(Map<String, dynamic>.from(snapshot))
          : null,
    );
  }

  final String status;
  final String? admissionId;
  final String? childId;
  final int commandSeq;
  final String? pendingCommand;
  final String? sessionId;
  final String workspaceFormat;
  final ParentLiveLessonWaiting waiting;
  final ParentHomeworkPlaySnapshot? snapshot;

  bool get isOk => status == 'ok';

  bool get isGone =>
      status == 'left' ||
      status == 'ended' ||
      status == 'expired' ||
      status == 'guest';

  bool get hasPlayCommand => pendingCommand == 'play_trainer' && snapshot != null;
}
