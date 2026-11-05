class LessonCallPassOutcome {
  const LessonCallPassOutcome.pass(this.pass) : domain = '', moving = false;
  const LessonCallPassOutcome.moving(this.domain) : pass = null, moving = true;
  const LessonCallPassOutcome.none() : domain = '', moving = false, pass = null;

  final String domain;
  final bool moving;
  final LessonCallPass? pass;

  static LessonCallPassOutcome fromBody(Map<String, dynamic>? json) {
    if (json == null) return const LessonCallPassOutcome.none();
    if (json['status'] == 'moving' || json['code'] == 'moving') {
      final domain = json['domain'];
      return LessonCallPassOutcome.moving(domain is String ? domain : '');
    }
    final pass = LessonCallPass.fromJson(json);
    if (pass == null) return const LessonCallPassOutcome.none();
    return LessonCallPassOutcome.pass(pass);
  }
}

class LessonCallPass {
  const LessonCallPass({
    required this.displayName,
    required this.domain,
    required this.jwt,
    required this.room,
    required this.xmppDomain,
    this.roomJid,
    this.mainRoom,
    this.teacherName = '',
    this.workspaceFormat = 'board',
  });

  final String displayName;
  final String domain;
  final String jwt;
  final String room;
  final String xmppDomain;
  final String? roomJid;
  final String? mainRoom;
  String get addressKey => '$room|${roomJid ?? ''}|${mainRoom ?? ''}';
  final String teacherName;
  final String workspaceFormat;

  static final _host = RegExp(r'^[A-Za-z0-9.-]+$');
  static final _room = RegExp(r'^[a-z0-9][a-z0-9._-]{0,64}$');

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
    final roomJid = json['roomJid'];
    final mainRoom = json['mainRoom'];
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
    if (!_room.hasMatch(room)) return null;
    if (roomJid != null || mainRoom != null) {
      if (roomJid is! String ||
          mainRoom is! String ||
          !_room.hasMatch(mainRoom) ||
          mainRoom == room ||
          roomJid != '$room@breakout.${xmppDomain.toLowerCase()}') {
        return null;
      }
    }

    return LessonCallPass(
      displayName: displayName,
      domain: domain,
      jwt: jwt,
      room: room,
      xmppDomain: xmppDomain,
      roomJid: roomJid as String?,
      mainRoom: mainRoom as String?,
      teacherName: teacherName is String ? teacherName : '',
      workspaceFormat: 'board',
    );
  }

  Map<String, String> toStageJson() => {
    'displayName': displayName,
    'domain': domain,
    'jwt': jwt,
    'room': room,
    'xmppDomain': xmppDomain,
    'roomJid': ?roomJid,
    'mainRoom': ?mainRoom,
    'teacherName': teacherName,
    'workspaceFormat': workspaceFormat,
  };
}

class LessonCallTeachers {
  const LessonCallTeachers({
    required this.ids,
    required this.primary,
    this.scopeId = '',
    this.participants = const [],
    this.observers = const [],
    this.roomAudio = const [],
    this.mediaControllers = const [],
  });

  final List<String> ids;
  final String primary;
  final String scopeId;
  final List<String> participants;
  final List<String> observers;
  final List<String> roomAudio;
  final List<String> mediaControllers;

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
      observers: idsOf(json['observerEndpointIds']),
      roomAudio: idsOf(json['roomAudioEndpointIds']),
      mediaControllers: idsOf(json['mediaControllerEndpointIds']),
    );
  }

  Map<String, dynamic> toBoardJson() => {
    'scopeId': scopeId,
    'teacherEndpointIds': ids,
    'teacherEndpointId': primary.isEmpty ? null : primary,
    'participantEndpointIds': participants,
    if (observers.isNotEmpty) 'observerEndpointIds': observers,
    if (roomAudio.isNotEmpty) 'roomAudioEndpointIds': roomAudio,
  };
}
