import 'package:larnes_mobile/features/parent/models/parent_program.dart';

class ProgramPlayerLessonBounds {
  const ProgramPlayerLessonBounds({
    required this.currentInLesson,
    required this.lessonOrdinal,
    required this.topicOrdinal,
    required this.totalInLesson,
  });

  final int currentInLesson;
  final int lessonOrdinal;
  final int topicOrdinal;
  final int totalInLesson;
}

ProgramPlayerLessonBounds computeProgramPlayerLessonBounds(
  List<ParentProgramPlayStep> steps,
  int stepIndex,
) {
  final currentStep = steps.elementAtOrNull(stepIndex);
  if (currentStep == null) {
    return const ProgramPlayerLessonBounds(
      currentInLesson: 0,
      lessonOrdinal: 0,
      topicOrdinal: 0,
      totalInLesson: 0,
    );
  }

  var lessonStart = stepIndex;
  while (lessonStart > 0) {
    final previous = steps[lessonStart - 1];
    if (previous.topicOrdinal != currentStep.topicOrdinal ||
        previous.lessonOrdinal != currentStep.lessonOrdinal) {
      break;
    }
    lessonStart -= 1;
  }

  var lessonEnd = stepIndex;
  while (lessonEnd < steps.length - 1 && !steps[lessonEnd].isLastInLesson) {
    lessonEnd += 1;
  }

  return ProgramPlayerLessonBounds(
    currentInLesson: stepIndex - lessonStart + 1,
    lessonOrdinal: currentStep.lessonOrdinal,
    topicOrdinal: currentStep.topicOrdinal,
    totalInLesson: lessonEnd - lessonStart + 1,
  );
}
