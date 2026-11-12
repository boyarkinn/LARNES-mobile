import 'package:larnes_mobile/trainers/mental_arithmetic/shared/topic_example_generation.dart';

TopicExampleProfile topicExplanationExampleProfile(String lessonId) {
  final repeated = RegExp(r'^simple-([4-9])\1$').firstMatch(lessonId);
  if (repeated != null) {
    return TopicExampleProfile(
      'simple-2digit',
      repeatedDigit: int.parse(repeated[1]!),
    );
  }
  if (lessonId == 'simple-000') {
    return const TopicExampleProfile('simple-3digit');
  }
  if (RegExp(r'^(brother|friend|friend-brother)-\d$').hasMatch(lessonId)) {
    return TopicExampleProfile('$lessonId-1digit');
  }
  return TopicExampleProfile(lessonId);
}
