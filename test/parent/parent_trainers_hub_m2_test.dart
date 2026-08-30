import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parent trainers hub M2 smoke', () {
    late String studyHubSource;
    late String routerSource;
    late String parentApiSource;

    setUp(() {
      studyHubSource = File('lib/features/parent/screens/study_hub_screen.dart').readAsStringSync();
      routerSource = File('lib/app/router.dart').readAsStringSync();
      parentApiSource = File('lib/core/api/parent_api.dart').readAsStringSync();
    });

    test('study hub fetches trainers availability and renders card before courses', () {
      expect(studyHubSource, contains('hasPublishedTrainers'));
      expect(studyHubSource, contains('parentStudyTrainersCard'));
      expect(studyHubSource, contains('trainersHubCardTokens'));
      expect(studyHubSource, contains('HubCardIconKind.trainers'));

      final trainersIndex = studyHubSource.indexOf('parentStudyTrainersCard');
      final homeworkIndex = studyHubSource.indexOf('parentHomeworkTitle');
      final coursesIndex = studyHubSource.indexOf('parentStudyCoursesCard');

      expect(trainersIndex, greaterThan(homeworkIndex));
      expect(coursesIndex, greaterThan(trainersIndex));
    });

    test('router registers trainers catalog and play routes', () {
      expect(routerSource, contains("path: 'trainers'"));
      expect(routerSource, contains("path: 'play/:trainerKey'"));
      expect(routerSource, contains('TrainersDirectionsScreen'));
      expect(routerSource, contains('TrainersListScreen'));
      expect(routerSource, contains('TrainerParamsScreen'));
      expect(routerSource, contains('TrainerPlayScreen'));
    });

    test('parent API calls trainers available endpoint', () {
      expect(parentApiSource, contains('/api/mobile/parent/trainers/available'));
      expect(parentApiSource, contains("data['available']"));
    });
  });
}
