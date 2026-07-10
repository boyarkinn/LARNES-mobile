enum TrainerWorkflowPlatform { web, mobile }

enum TrainerReleaseLifecycleStatus { inDevelopment, readyForRelease }

enum TrainerSignoffStatus { needsFixes, readyForRelease }

enum TrainerDevCommentStatus { inProgress, implemented, rejected }

class TrainerWorkflowAttachment {
  const TrainerWorkflowAttachment({
    required this.id,
    required this.dataUrl,
    required this.mime,
    this.width,
    this.height,
  });

  factory TrainerWorkflowAttachment.fromJson(Map<String, dynamic> json) {
    return TrainerWorkflowAttachment(
      id: json['id'] as String,
      dataUrl: json['dataUrl'] as String,
      mime: json['mime'] as String,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  final String id;
  final String dataUrl;
  final String mime;
  final int? width;
  final int? height;
}

class TrainerDevFeedItem {
  const TrainerDevFeedItem({
    required this.id,
    required this.body,
    required this.status,
    required this.createdAt,
    required this.authorName,
    required this.authorId,
    required this.attachments,
  });

  factory TrainerDevFeedItem.fromJson(Map<String, dynamic> json) {
    final attachmentsJson = json['attachments'] as List<dynamic>? ?? const [];
    final author = Map<String, dynamic>.from(json['author'] as Map? ?? const {});

    return TrainerDevFeedItem(
      id: json['id'] as String,
      body: json['body'] as String,
      status: _parseCommentStatus(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      authorName: author['displayName'] as String? ?? '',
      authorId: author['id'] as String? ?? '',
      attachments: attachmentsJson
          .map(
            (item) => TrainerWorkflowAttachment.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  final String id;
  final String body;
  final TrainerDevCommentStatus status;
  final DateTime createdAt;
  final String authorName;
  final String authorId;
  final List<TrainerWorkflowAttachment> attachments;
}

class TrainerWorkflowReviewer {
  const TrainerWorkflowReviewer({
    required this.userId,
    required this.displayName,
    required this.signoffStatus,
  });

  factory TrainerWorkflowReviewer.fromJson(Map<String, dynamic> json) {
    return TrainerWorkflowReviewer(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      signoffStatus: _parseSignoffStatus(json['signoffStatus'] as String?),
    );
  }

  final String userId;
  final String displayName;
  final TrainerSignoffStatus? signoffStatus;
}

class TrainerWorkflowRelease {
  const TrainerWorkflowRelease({
    required this.lifecycleStatus,
    required this.trainerKey,
    required this.updatedAt,
  });

  factory TrainerWorkflowRelease.fromJson(Map<String, dynamic> json) {
    return TrainerWorkflowRelease(
      lifecycleStatus: _parseLifecycleStatus(json['lifecycleStatus'] as String?),
      trainerKey: json['trainerKey'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final TrainerReleaseLifecycleStatus lifecycleStatus;
  final String trainerKey;
  final DateTime updatedAt;
}

class TrainerWorkflowSnapshot {
  const TrainerWorkflowSnapshot({
    required this.trainerKey,
    required this.platform,
    required this.inProgressCommentCount,
    required this.isReadyForRelease,
    required this.release,
    required this.reviewers,
    required this.feed,
  });

  factory TrainerWorkflowSnapshot.fromJson(Map<String, dynamic> json) {
    final reviewersJson = json['reviewers'] as List<dynamic>? ?? const [];
    final feedJson = json['feed'] as List<dynamic>? ?? const [];

    return TrainerWorkflowSnapshot(
      trainerKey: json['trainerKey'] as String,
      platform: _parsePlatform(json['platform'] as String?),
      inProgressCommentCount: json['inProgressCommentCount'] as int? ?? 0,
      isReadyForRelease: json['isReadyForRelease'] as bool? ?? false,
      release: TrainerWorkflowRelease.fromJson(
        Map<String, dynamic>.from(json['release'] as Map? ?? const {}),
      ),
      reviewers: reviewersJson
          .map(
            (item) => TrainerWorkflowReviewer.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      feed: feedJson
          .map(
            (item) => TrainerDevFeedItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  final String trainerKey;
  final TrainerWorkflowPlatform platform;
  final int inProgressCommentCount;
  final bool isReadyForRelease;
  final TrainerWorkflowRelease release;
  final List<TrainerWorkflowReviewer> reviewers;
  final List<TrainerDevFeedItem> feed;
}

class TrainerWorkflowMeta {
  const TrainerWorkflowMeta({
    required this.key,
    required this.title,
    required this.direction,
  });

  factory TrainerWorkflowMeta.fromJson(Map<String, dynamic> json) {
    return TrainerWorkflowMeta(
      key: json['key'] as String,
      title: json['title'] as String,
      direction: json['direction'] as String? ?? 'mental',
    );
  }

  final String key;
  final String title;
  final String direction;
}

class TrainerWorkflowDetail {
  const TrainerWorkflowDetail({
    required this.trainer,
    required this.currentUserId,
    required this.web,
    required this.mobile,
  });

  factory TrainerWorkflowDetail.fromJson(Map<String, dynamic> json) {
    return TrainerWorkflowDetail(
      trainer: TrainerWorkflowMeta.fromJson(
        Map<String, dynamic>.from(json['trainer'] as Map? ?? const {}),
      ),
      currentUserId: json['currentUserId'] as String,
      web: TrainerWorkflowSnapshot.fromJson(
        Map<String, dynamic>.from(json['web'] as Map? ?? const {}),
      ),
      mobile: TrainerWorkflowSnapshot.fromJson(
        Map<String, dynamic>.from(json['mobile'] as Map? ?? const {}),
      ),
    );
  }

  final TrainerWorkflowMeta trainer;
  final String currentUserId;
  final TrainerWorkflowSnapshot web;
  final TrainerWorkflowSnapshot mobile;

  TrainerWorkflowSnapshot snapshotFor(TrainerWorkflowPlatform platform) {
    return platform == TrainerWorkflowPlatform.web ? web : mobile;
  }
}

TrainerWorkflowPlatform _parsePlatform(String? raw) {
  return raw == 'mobile' ? TrainerWorkflowPlatform.mobile : TrainerWorkflowPlatform.web;
}

TrainerReleaseLifecycleStatus _parseLifecycleStatus(String? raw) {
  if (raw == 'ready_for_release') {
    return TrainerReleaseLifecycleStatus.readyForRelease;
  }
  return TrainerReleaseLifecycleStatus.inDevelopment;
}

TrainerSignoffStatus? _parseSignoffStatus(String? raw) {
  switch (raw) {
    case 'needs_fixes':
      return TrainerSignoffStatus.needsFixes;
    case 'ready_for_release':
      return TrainerSignoffStatus.readyForRelease;
    default:
      return null;
  }
}

TrainerDevCommentStatus _parseCommentStatus(String? raw) {
  switch (raw) {
    case 'implemented':
      return TrainerDevCommentStatus.implemented;
    case 'rejected':
      return TrainerDevCommentStatus.rejected;
    case 'in_progress':
    default:
      return TrainerDevCommentStatus.inProgress;
  }
}

String signoffStatusToApi(TrainerSignoffStatus status) {
  switch (status) {
    case TrainerSignoffStatus.needsFixes:
      return 'needs_fixes';
    case TrainerSignoffStatus.readyForRelease:
      return 'ready_for_release';
  }
}

String commentStatusToApi(TrainerDevCommentStatus status) {
  switch (status) {
    case TrainerDevCommentStatus.inProgress:
      return 'in_progress';
    case TrainerDevCommentStatus.implemented:
      return 'implemented';
    case TrainerDevCommentStatus.rejected:
      return 'rejected';
  }
}

String workflowPlatformToApi(TrainerWorkflowPlatform platform) {
  return platform == TrainerWorkflowPlatform.web ? 'web' : 'mobile';
}
