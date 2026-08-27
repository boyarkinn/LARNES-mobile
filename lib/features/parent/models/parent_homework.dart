enum ParentHomeworkTab {
  due,
  upcoming,
  completed;

  static ParentHomeworkTab fromApiValue(String? value) {
    return ParentHomeworkTab.values.firstWhere(
      (tab) => tab.name == value,
      orElse: () => ParentHomeworkTab.due,
    );
  }

  String get apiValue => name;
}

class ParentHomeworkAssignment {
  const ParentHomeworkAssignment({
    required this.assignmentId,
    required this.recipientId,
    required this.title,
    required this.displayStatus,
    required this.status,
    required this.sentAt,
    required this.availableOn,
    this.cancelledAt,
    this.completedAt,
    required this.currentStepIndex,
    required this.totalSteps,
  });

  factory ParentHomeworkAssignment.fromJson(Map<String, dynamic> json) {
    return ParentHomeworkAssignment(
      assignmentId: json['assignmentId'] as String,
      recipientId: json['recipientId'] as String,
      title: json['title'] as String,
      displayStatus: json['displayStatus'] as String,
      status: json['status'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      availableOn: json['availableOn'] as String,
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      currentStepIndex: json['currentStepIndex'] as int? ?? 0,
      totalSteps: json['totalSteps'] as int? ?? 0,
    );
  }

  final String assignmentId;
  final String recipientId;
  final String title;
  final String displayStatus;
  final String status;
  final DateTime sentAt;
  final String availableOn;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final int currentStepIndex;
  final int totalSteps;

  bool get canOpen =>
      displayStatus == 'assigned' ||
      displayStatus == 'in_progress' ||
      displayStatus == 'completed';
}

class ParentHomeworkListPage {
  const ParentHomeworkListPage({
    required this.tab,
    required this.counts,
    required this.assignments,
  });

  factory ParentHomeworkListPage.fromJson(Map<String, dynamic> json) {
    final countsJson = Map<String, dynamic>.from(json['counts'] as Map);
    final counts = <ParentHomeworkTab, int>{
      for (final tab in ParentHomeworkTab.values)
        tab: countsJson[tab.name] as int? ?? 0,
    };

    final assignments = (json['assignments'] as List<dynamic>? ?? const [])
        .map(
          (item) => ParentHomeworkAssignment.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    return ParentHomeworkListPage(
      tab: ParentHomeworkTab.fromApiValue(json['tab'] as String?),
      counts: counts,
      assignments: assignments,
    );
  }

  final ParentHomeworkTab tab;
  final Map<ParentHomeworkTab, int> counts;
  final List<ParentHomeworkAssignment> assignments;
}

class ParentHomeworkPlayStep {
  const ParentHomeworkPlayStep({
    required this.id,
    required this.trainerKey,
    required this.params,
    this.runtimeSnapshot,
    required this.sortOrder,
  });

  factory ParentHomeworkPlayStep.fromJson(Map<String, dynamic> json) {
    final rawParams = json['params'];
    final rawRuntimeSnapshot = json['runtimeSnapshot'];
    return ParentHomeworkPlayStep(
      id: json['id'] as String,
      trainerKey: json['trainerKey'] as String,
      params: rawParams is Map
          ? Map<String, dynamic>.from(rawParams)
          : const {},
      runtimeSnapshot: rawRuntimeSnapshot is Map
          ? Map<String, dynamic>.from(rawRuntimeSnapshot)
          : null,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  final String id;
  final String trainerKey;
  final Map<String, dynamic> params;
  final Map<String, dynamic>? runtimeSnapshot;
  final int sortOrder;
}

class ParentHomeworkPlaySnapshot {
  const ParentHomeworkPlaySnapshot({
    required this.assignmentId,
    required this.childId,
    required this.recipientId,
    required this.title,
    required this.status,
    required this.availableOn,
    this.cancelledAt,
    required this.currentStepIndex,
    required this.steps,
  });

  factory ParentHomeworkPlaySnapshot.fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List<dynamic>? ?? const [])
        .map(
          (item) => ParentHomeworkPlayStep.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    return ParentHomeworkPlaySnapshot(
      assignmentId: json['assignmentId'] as String,
      childId: json['childId'] as String,
      recipientId: json['recipientId'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      availableOn: json['availableOn'] as String,
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
      currentStepIndex: json['currentStepIndex'] as int? ?? 0,
      steps: steps,
    );
  }

  final String assignmentId;
  final String childId;
  final String recipientId;
  final String title;
  final String status;
  final String availableOn;
  final DateTime? cancelledAt;
  final int currentStepIndex;
  final List<ParentHomeworkPlayStep> steps;

  bool get isCompleted => status == 'completed';
}
