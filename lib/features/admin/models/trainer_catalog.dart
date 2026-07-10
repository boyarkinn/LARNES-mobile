enum TrainerCatalogDirection { mental, math, reading }

enum TrainerReleaseStatus { inDevelopment, readyForRelease }

class TrainerCatalogItem {
  const TrainerCatalogItem({
    required this.key,
    required this.title,
    required this.webStatus,
    required this.mobileStatus,
    required this.inProgressCommentCount,
  });

  factory TrainerCatalogItem.fromJson(Map<String, dynamic> json) {
    return TrainerCatalogItem(
      key: json['key'] as String,
      title: json['title'] as String,
      webStatus: _parseStatus(json['webStatus'] as String?),
      mobileStatus: _parseStatus(json['mobileStatus'] as String?),
      inProgressCommentCount: json['inProgressCommentCount'] as int? ?? 0,
    );
  }

  final String key;
  final String title;
  final TrainerReleaseStatus webStatus;
  final TrainerReleaseStatus mobileStatus;
  final int inProgressCommentCount;

  static TrainerReleaseStatus _parseStatus(String? raw) {
    if (raw == 'ready_for_release') {
      return TrainerReleaseStatus.readyForRelease;
    }
    return TrainerReleaseStatus.inDevelopment;
  }
}

class TrainerCatalogGroup {
  const TrainerCatalogGroup({
    required this.direction,
    required this.trainers,
  });

  factory TrainerCatalogGroup.fromJson(Map<String, dynamic> json) {
    final trainersJson = json['trainers'] as List<dynamic>? ?? const [];
    return TrainerCatalogGroup(
      direction: _parseDirection(json['direction'] as String?),
      trainers: trainersJson
          .map((item) => TrainerCatalogItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  final TrainerCatalogDirection direction;
  final List<TrainerCatalogItem> trainers;

  static TrainerCatalogDirection _parseDirection(String? raw) {
    switch (raw) {
      case 'math':
        return TrainerCatalogDirection.math;
      case 'reading':
        return TrainerCatalogDirection.reading;
      case 'mental':
      default:
        return TrainerCatalogDirection.mental;
    }
  }
}

class TrainerCatalogSnapshot {
  const TrainerCatalogSnapshot({required this.groups});

  factory TrainerCatalogSnapshot.fromJson(Map<String, dynamic> json) {
    final groupsJson = json['groups'] as List<dynamic>? ?? const [];
    return TrainerCatalogSnapshot(
      groups: groupsJson
          .map((item) => TrainerCatalogGroup.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  final List<TrainerCatalogGroup> groups;
}
