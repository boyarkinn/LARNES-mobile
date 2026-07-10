import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/admin/models/trainer_catalog.dart';

void main() {
  group('TrainerCatalogSnapshot.fromJson', () {
    test('parses grouped catalog payload', () {
      final snapshot = TrainerCatalogSnapshot.fromJson({
        'status': 'success',
        'groups': [
          {
            'direction': 'mental',
            'trainers': [
              {
                'key': 'flashcard-digit-match',
                'title': 'Flashcards',
                'webStatus': 'in_development',
                'mobileStatus': 'ready_for_release',
                'inProgressCommentCount': 2,
              },
            ],
          },
        ],
      });

      expect(snapshot.groups, hasLength(1));
      expect(snapshot.groups.first.direction, TrainerCatalogDirection.mental);
      expect(snapshot.groups.first.trainers, hasLength(1));

      final trainer = snapshot.groups.first.trainers.first;
      expect(trainer.key, 'flashcard-digit-match');
      expect(trainer.title, 'Flashcards');
      expect(trainer.webStatus, TrainerReleaseStatus.inDevelopment);
      expect(trainer.mobileStatus, TrainerReleaseStatus.readyForRelease);
      expect(trainer.inProgressCommentCount, 2);
    });

    test('normalizes unknown status to in development', () {
      final item = TrainerCatalogItem.fromJson({
        'key': 'demo',
        'title': 'Demo',
        'webStatus': 'not_ported',
        'mobileStatus': null,
        'inProgressCommentCount': 0,
      });

      expect(item.webStatus, TrainerReleaseStatus.inDevelopment);
      expect(item.mobileStatus, TrainerReleaseStatus.inDevelopment);
    });
  });
}
