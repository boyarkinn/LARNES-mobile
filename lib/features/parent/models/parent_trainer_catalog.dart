const trainerDirectionSlugs = ['mental', 'math', 'reading', 'intel'];

bool isTrainerDirectionSlug(String value) {
  return trainerDirectionSlugs.contains(value);
}

class ParentTrainerCatalogItem {
  const ParentTrainerCatalogItem({
    required this.direction,
    required this.key,
    required this.title,
  });

  factory ParentTrainerCatalogItem.fromJson(Map<String, dynamic> json) {
    return ParentTrainerCatalogItem(
      direction: json['direction'] as String? ?? '',
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }

  final String direction;
  final String key;
  final String title;
}

class ParentTrainerCatalogGroup {
  const ParentTrainerCatalogGroup({
    required this.direction,
    required this.trainers,
  });

  factory ParentTrainerCatalogGroup.fromJson(Map<String, dynamic> json) {
    final trainers = json['trainers'] as List<dynamic>? ?? const [];
    return ParentTrainerCatalogGroup(
      direction: json['direction'] as String? ?? '',
      trainers: trainers
          .map(
            (item) => ParentTrainerCatalogItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  final String direction;
  final List<ParentTrainerCatalogItem> trainers;
}

class ParentTrainerCatalogPage {
  const ParentTrainerCatalogPage({
    required this.directionLabels,
    required this.groups,
    required this.locale,
  });

  factory ParentTrainerCatalogPage.fromJson(Map<String, dynamic> json) {
    final labelsRaw = json['directionLabels'];
    final directionLabels = <String, String>{};
    if (labelsRaw is Map) {
      for (final entry in labelsRaw.entries) {
        directionLabels['${entry.key}'] = '${entry.value}';
      }
    }

    final groupsRaw = json['groups'] as List<dynamic>? ?? const [];
    return ParentTrainerCatalogPage(
      directionLabels: directionLabels,
      groups: groupsRaw
          .map(
            (item) => ParentTrainerCatalogGroup.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      locale: json['locale'] as String? ?? 'ru',
    );
  }

  final Map<String, String> directionLabels;
  final List<ParentTrainerCatalogGroup> groups;
  final String locale;

  String directionLabel(String direction) {
    return directionLabels[direction] ?? direction;
  }

  ParentTrainerCatalogGroup? groupForDirection(String direction) {
    for (final group in groups) {
      if (group.direction == direction) {
        return group;
      }
    }
    return null;
  }
}
