enum TrainerCatalogDirection { mental, math, reading }

enum TrainerPublicationStatus { inDevelopment, readyToPublish, published }

class TrainerCatalogItem {
  const TrainerCatalogItem({
    required this.key,
    required this.title,
    required this.publicationStatus,
  });

  factory TrainerCatalogItem.fromJson(Map<String, dynamic> json) {
    return TrainerCatalogItem(
      key: json['key'] as String,
      title: json['title'] as String,
      publicationStatus: _parsePublicationStatus(json['publicationStatus'] as String?),
    );
  }

  final String key;
  final String title;
  final TrainerPublicationStatus publicationStatus;

  static TrainerPublicationStatus _parsePublicationStatus(String? raw) {
    switch (raw) {
      case 'ready_to_publish':
        return TrainerPublicationStatus.readyToPublish;
      case 'published':
        return TrainerPublicationStatus.published;
      case 'in_development':
      default:
        return TrainerPublicationStatus.inDevelopment;
    }
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
