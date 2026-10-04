class LessonCallPass {
  const LessonCallPass({
    required this.displayName,
    required this.domain,
    required this.jwt,
    required this.room,
    required this.xmppDomain,
    this.teacherName = '',
  });

  final String displayName;
  final String domain;
  final String jwt;
  final String room;
  final String xmppDomain;
  final String teacherName;

  static final _host = RegExp(r'^[A-Za-z0-9.-]+$');

  static LessonCallPass? fromJson(Map<String, dynamic> json) {
    if (json['status'] != 'success') {
      return null;
    }

    final displayName = json['displayName'];
    final domain = json['domain'];
    final jwt = json['jwt'];
    final room = json['room'];
    final xmppDomain = json['xmppDomain'];
    final teacherName = json['teacherName'];
    if (displayName is! String ||
        domain is! String ||
        jwt is! String ||
        room is! String ||
        xmppDomain is! String ||
        displayName.isEmpty ||
        jwt.isEmpty ||
        room.isEmpty ||
        !_host.hasMatch(domain) ||
        !_host.hasMatch(xmppDomain)) {
      return null;
    }

    return LessonCallPass(
      displayName: displayName,
      domain: domain,
      jwt: jwt,
      room: room,
      xmppDomain: xmppDomain,
      teacherName: teacherName is String ? teacherName : '',
    );
  }

  Map<String, String> toStageJson() => {
    'displayName': displayName,
    'domain': domain,
    'jwt': jwt,
    'room': room,
    'xmppDomain': xmppDomain,
    'teacherName': teacherName,
  };
}

class LessonCallTeachers {
  const LessonCallTeachers({
    required this.ids,
    required this.primary,
    this.scopeId = '',
    this.participants = const [],
  });

  final List<String> ids;
  final String primary;
  final String scopeId;
  final List<String> participants;

  factory LessonCallTeachers.fromJson(Map<String, dynamic> json) {
    List<String> idsOf(dynamic value) => [
      if (value is List)
        for (final id in value)
          if (id is String && id.isNotEmpty) id,
    ];
    return LessonCallTeachers(
      ids: idsOf(json['teacherEndpointIds']),
      primary: json['teacherEndpointId'] is String
          ? json['teacherEndpointId'] as String
          : '',
      scopeId: json['scopeId'] is String ? json['scopeId'] as String : '',
      participants: idsOf(json['participantEndpointIds']),
    );
  }

  Map<String, dynamic> toBoardJson() => {
    'scopeId': scopeId,
    'teacherEndpointIds': ids,
    'teacherEndpointId': primary.isEmpty ? null : primary,
    'participantEndpointIds': participants,
  };
}
