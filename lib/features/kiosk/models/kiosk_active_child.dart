import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';

class KioskActiveChild {
  const KioskActiveChild({
    required this.childId,
    required this.childDisplayName,
    required this.childCardColor,
    this.childGender,
    this.childGivenName,
    this.childLastName,
    required this.lessonSessionId,
  });

  factory KioskActiveChild.fromJson(Map<String, dynamic> json) {
    return KioskActiveChild(
      childId: json['childId'] as String,
      childDisplayName: json['childDisplayName'] as String,
      childCardColor: childCardColorFromString(json['childCardColor'] as String?),
      childGender: json['childGender'] as String?,
      childGivenName: json['childGivenName'] as String?,
      childLastName: json['childLastName'] as String?,
      lessonSessionId: json['lessonSessionId'] as String,
    );
  }

  final String childId;
  final String childDisplayName;
  final ChildCardColor childCardColor;
  final String? childGender;
  final String? childGivenName;
  final String? childLastName;
  final String lessonSessionId;
}
