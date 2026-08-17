import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/admin/models/trainer_catalog.dart';

void main() {
  group('TrainerCatalogSnapshot.fromJson', () {
    test('parses grouped catalog payload with publicationStatus', () {
      final snapshot = TrainerCatalogSnapshot.fromJson({
        'status': 'success',
        'groups': [
          {
            'direction': 'mental',
            'trainers': [
              {
                'key': 'flashcard-digit-match',
                'title': 'Flashcards',
                'publicationStatus': 'ready_to_publish',
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
      expect(trainer.publicationStatus, TrainerPublicationStatus.readyToPublish);
    });

    test('normalizes unknown publication status to in development', () {
      final item = TrainerCatalogItem.fromJson({
        'key': 'demo',
        'title': 'Demo',
        'publicationStatus': 'unknown',
      });

      expect(item.publicationStatus, TrainerPublicationStatus.inDevelopment);
    });
  });
}
