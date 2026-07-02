enum ParentProgramProgressStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  completed('completed');

  const ParentProgramProgressStatus(this.apiValue);

  final String apiValue;

  static ParentProgramProgressStatus fromApiValue(String? value) {
    return ParentProgramProgressStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => ParentProgramProgressStatus.notStarted,
    );
  }
}

class ParentProgramCard {
  const ParentProgramCard({
    required this.programId,
    required this.title,
    required this.progressStatus,
  });

  factory ParentProgramCard.fromJson(Map<String, dynamic> json) {
    return ParentProgramCard(
      programId: json['programId'] as String,
      title: json['title'] as String,
      progressStatus: ParentProgramProgressStatus.fromApiValue(
        json['progressStatus'] as String?,
      ),
    );
  }

  final String programId;
  final String title;
  final ParentProgramProgressStatus progressStatus;
}

class ParentProgramPlayStep {
  const ParentProgramPlayStep({
    required this.id,
    required this.trainerKey,
    required this.params,
    required this.topicOrdinal,
    required this.lessonOrdinal,
    required this.isLastInLesson,
    required this.isLastInProgram,
  });

  factory ParentProgramPlayStep.fromJson(Map<String, dynamic> json) {
    final rawParams = json['params'];
    return ParentProgramPlayStep(
      id: json['id'] as String,
      trainerKey: json['trainerKey'] as String,
      params: rawParams is Map ? Map<String, dynamic>.from(rawParams) : const {},
      topicOrdinal: json['topicOrdinal'] as int? ?? 0,
      lessonOrdinal: json['lessonOrdinal'] as int? ?? 0,
      isLastInLesson: json['isLastInLesson'] as bool? ?? false,
      isLastInProgram: json['isLastInProgram'] as bool? ?? false,
    );
  }

  final String id;
  final String trainerKey;
  final Map<String, dynamic> params;
  final int topicOrdinal;
  final int lessonOrdinal;
  final bool isLastInLesson;
  final bool isLastInProgram;
}

enum ParentProgramUnavailableReason {
  emptyProgram('empty_program'),
  emptyLesson('empty_lesson');

  const ParentProgramUnavailableReason(this.apiValue);

  final String apiValue;

  static ParentProgramUnavailableReason? fromApiValue(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final reason in ParentProgramUnavailableReason.values) {
      if (reason.apiValue == value) {
        return reason;
      }
    }
    return null;
  }
}

class ParentProgramPlaySnapshot {
  const ParentProgramPlaySnapshot({
    required this.childId,
    required this.programId,
    required this.title,
    required this.status,
    required this.topicOrdinal,
    required this.lessonOrdinal,
    required this.steps,
    this.unavailableReason,
  });

  factory ParentProgramPlaySnapshot.fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List<dynamic>? ?? const [])
        .map(
          (item) => ParentProgramPlayStep.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    return ParentProgramPlaySnapshot(
      childId: json['childId'] as String,
      programId: json['programId'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      topicOrdinal: json['topicOrdinal'] as int? ?? 0,
      lessonOrdinal: json['lessonOrdinal'] as int? ?? 0,
      steps: steps,
      unavailableReason: ParentProgramUnavailableReason.fromApiValue(
        json['unavailableReason'] as String?,
      ),
    );
  }

  final String childId;
  final String programId;
  final String title;
  final String status;
  final int topicOrdinal;
  final int lessonOrdinal;
  final List<ParentProgramPlayStep> steps;
  final ParentProgramUnavailableReason? unavailableReason;

  bool get isCompleted => status == 'completed';
}

class ParentProgramCompleteLessonResult {
  const ParentProgramCompleteLessonResult({
    required this.progressStatus,
  });

  final String progressStatus;

  bool get isProgramCompleted => progressStatus == 'completed';
}
