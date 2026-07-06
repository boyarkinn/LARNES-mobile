import 'package:larnes_mobile/features/network/models/network_device.dart';

class KioskDeviceLessonBinding {
  const KioskDeviceLessonBinding({
    required this.commandSeq,
    required this.lessonSessionId,
    required this.status,
    this.pendingCommand,
  });

  factory KioskDeviceLessonBinding.fromJson(Map<String, dynamic> json) {
    return KioskDeviceLessonBinding(
      commandSeq: json['commandSeq'] as int,
      lessonSessionId: json['lessonSessionId'] as String,
      status: json['status'] as String,
      pendingCommand: json['pendingCommand'] as String?,
    );
  }

  final int commandSeq;
  final String lessonSessionId;
  final String status;
  final String? pendingCommand;
}

class KioskDeviceContext {
  const KioskDeviceContext({
    required this.deviceId,
    required this.kind,
    this.centerName,
    this.classroomId,
    this.classroomTitle,
    this.slotLabel,
    this.lesson,
  });

  factory KioskDeviceContext.fromJson(Map<String, dynamic> json) {
    final rawLesson = json['lesson'];
    return KioskDeviceContext(
      deviceId: json['deviceId'] as String,
      kind: networkDeviceKindFromString(json['kind'] as String?),
      centerName: json['centerName'] as String?,
      classroomId: json['classroomId'] as String?,
      classroomTitle: json['classroomTitle'] as String?,
      slotLabel: json['slotLabel'] as String?,
      lesson: rawLesson is Map
          ? KioskDeviceLessonBinding.fromJson(
              Map<String, dynamic>.from(rawLesson),
            )
          : null,
    );
  }

  final String deviceId;
  final NetworkDeviceKind kind;
  final String? centerName;
  final String? classroomId;
  final String? classroomTitle;
  final String? slotLabel;
  final KioskDeviceLessonBinding? lesson;
}
