import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/shared/grouped_multi_select.dart';
import 'package:larnes_mobile/trainers/reading/shared/word_list.dart';
import 'package:larnes_mobile/trainers/reading/shared/content_bank.dart';
import 'package:larnes_mobile/trainers/catalog/reading_param_validators.dart';

void main() {
  test(
    'marathon accepts multiple subtopics and old selections; columns require one',
    () {
      final bank = {
        'libraryId': readingContentBankLibraryId,
        'categoryIds': ['a', 'b', 'a'],
      };
      expect(validateReadingMarathonParams({'contentBank': bank}).ok, isTrue);
      expect(readingWordListCategoryIds(bank), ['a', 'b']);
      expect(
        validateReadingWordColumnsParams({'contentBank': bank}).ok,
        isFalse,
      );
      expect(
        validateReadingMarathonParams({
          'contentBank': {
            'libraryId': readingContentBankLibraryId,
            'categoryId': 'old',
          },
        }).ok,
        isTrue,
      );
      expect(
        validateReadingMarathonParams({
          'contentBank': {
            'libraryId': readingContentBankLibraryId,
            'categoryId': 'old',
            'categoryIds': [],
          },
        }).ok,
        isFalse,
      );
    },
  );
  testWidgets(
    'shared picker selects a topic group and preserves warm-up per-option switches',
    (tester) async {
      ({List<String> selected, List<String> enabled})? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showGroupedMultiSelect(
                    context: context,
                    options: const [
                      GroupedSelectOption(
                        value: 'a',
                        label: 'A',
                        group: 'Topic 1',
                      ),
                      GroupedSelectOption(
                        value: 'b',
                        label: 'B',
                        group: 'Topic 1',
                      ),
                      GroupedSelectOption(
                        value: 'c',
                        label: 'C',
                        group: 'Topic 2',
                      ),
                    ],
                    selected: ['a'],
                    enabled: ['a'],
                    title: 'Topics',
                    searchLabel: 'Search',
                    allLabel: 'All',
                    clearLabel: 'Clear',
                    optionToggleLabel: 'Audio',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Topic 1'));
      await tester.pumpAndSettle();
      final switches = find.byType(Switch);
      expect(tester.widget<Switch>(switches.at(0)).value, isTrue);
      expect(tester.widget<Switch>(switches.at(1)).value, isTrue);
      await tester.tap(switches.at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(result?.selected, ['a', 'b']);
      expect(result?.enabled, ['b']);
    },
  );
}
