import 'package:larnes_mobile/features/parent/models/parent_child.dart';

class ParentLessonInviteChild {
  const ParentLessonInviteChild({
    required this.childId,
    required this.displayName,
    required this.presence,
  });

  factory ParentLessonInviteChild.fromJson(Map<String, dynamic> json) {
    return ParentLessonInviteChild(
      childId: json['childId'] as String,
      displayName: json['displayName'] as String? ?? '',
      presence: parentLiveLessonPresenceFromJson(json['presence'] as String?),
    );
  }

  final String childId;
  final String displayName;
  final ParentLiveLessonPresence presence;
}

class ParentLessonInvite {
  const ParentLessonInvite({
    required this.state,
    this.sessionId,
    this.token,
    this.children = const [],
  });

  factory ParentLessonInvite.fromJson(Map<String, dynamic> json) {
    final children = (json['children'] as List<dynamic>? ?? const [])
        .map(
          (item) => ParentLessonInviteChild.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    return ParentLessonInvite(
      state: json['state'] as String? ?? 'invalid',
      sessionId: json['sessionId'] as String?,
      token: json['token'] as String?,
      children: children,
    );
  }

  final String state;
  final String? sessionId;
  final String? token;
  final List<ParentLessonInviteChild> children;

  bool get isActive => state == 'active';
  bool get isExpired => state == 'expired';
}
