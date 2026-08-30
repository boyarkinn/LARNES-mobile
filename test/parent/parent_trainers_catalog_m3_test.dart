import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parent trainers catalog M3 smoke', () {
    late String directionsSource;
    late String listSource;
    late String parentApiSource;

    setUp(() {
      directionsSource =
          File('lib/features/parent/screens/trainers/trainers_directions_screen.dart')
              .readAsStringSync();
      listSource = File('lib/features/parent/screens/trainers/trainers_list_screen.dart')
          .readAsStringSync();
      parentApiSource = File('lib/core/api/parent_api.dart').readAsStringSync();
    });

    test('directions screen loads catalog with refresh and study hub cards', () {
      expect(directionsSource, contains('fetchTrainerCatalog'));
      expect(directionsSource, contains('RefreshIndicator'));
      expect(directionsSource, contains('StudyHubCard'));
      expect(directionsSource, contains('trainerDirectionHubCardTokens'));
      expect(directionsSource, contains('parentTrainersEmpty'));
    });

    test('list screen loads trainers for direction with empty state', () {
      expect(listSource, contains('fetchTrainerCatalog'));
      expect(listSource, contains('isTrainerDirectionSlug'));
      expect(listSource, contains('RefreshIndicator'));
      expect(listSource, contains('parentTrainersEmptyTrainersTitle'));
      expect(listSource, contains('trainers/\${widget.direction}/\${trainers[i].key}'));
    });

    test('parent API exposes trainer catalog endpoint', () {
      expect(parentApiSource, contains('/api/mobile/parent/children/\$childId/trainers/catalog'));
      expect(parentApiSource, contains('ParentTrainerCatalogPage'));
    });
  });
}
