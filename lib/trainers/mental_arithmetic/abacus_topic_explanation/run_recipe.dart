import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_topic_explanation/recipes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_chain_example.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';

PhysicalGesturePlan topicExplanationRunRecipe(
  String lessonId,
  Chain example, [
  String locale = 'ru-RU',
]) => withPhysicalChainExample(
  topicExplanationRecipe(lessonId),
  example,
  introAudioKey: 'explanation:abacus-topic:simple-1:example-intro',
  answerAudioKey: 'explanation:abacus-topic:answer',
  locale: locale,
);
