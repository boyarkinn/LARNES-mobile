enum ParentHomeworkTab {
  due,
  completed,
  overdue,
  upcoming;

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
    this.deadline,
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
      deadline: json['deadline'] as String?,
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
  final String? deadline;
  final DateTime? completedAt;
  final int currentStepIndex;
  final int totalSteps;
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
