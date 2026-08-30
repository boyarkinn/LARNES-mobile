import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/models/parent_trainer_catalog.dart';

void main() {
  group('ParentTrainerCatalogPage', () {
    test('parses catalog JSON from mobile API', () {
      final page = ParentTrainerCatalogPage.fromJson({
        'locale': 'ru',
        'directionLabels': {
          'mental': 'МЕНТАЛЬНАЯ АРИФМЕТИКА',
          'reading': 'ЧТЕНИЕ',
        },
        'groups': [
          {
            'direction': 'mental',
            'trainers': [
              {
                'direction': 'mental',
                'key': 'topic-chain-flash',
                'title': 'Topic chain flash',
              },
            ],
          },
        ],
      });

      expect(page.locale, 'ru');
      expect(page.directionLabel('mental'), 'МЕНТАЛЬНАЯ АРИФМЕТИКА');
      expect(page.groups.length, 1);
      expect(page.groups.first.trainers.first.key, 'topic-chain-flash');
      expect(page.groupForDirection('reading'), isNull);
    });

    test('serializes only stable trainer item fields', () {
      final item = ParentTrainerCatalogItem.fromJson({
        'direction': 'mental',
        'key': 'topic-chain-flash',
        'title': 'Topic chain flash',
        'extra': 'ignored-by-contract',
      });

      expect(item.key, 'topic-chain-flash');
      expect(item.title, 'Topic chain flash');
      expect(item.direction, 'mental');
    });
  });

  group('isTrainerDirectionSlug', () {
    test('accepts known trainer directions', () {
      expect(isTrainerDirectionSlug('mental'), isTrue);
      expect(isTrainerDirectionSlug('reading'), isTrue);
      expect(isTrainerDirectionSlug('unknown'), isFalse);
    });
  });
}
