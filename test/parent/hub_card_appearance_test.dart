import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/theme/hub_card_appearance.dart';

void main() {
  group('coursesHubCardTokens', () {
    test('uses violet tokens', () {
      final tokens = coursesHubCardTokens();
      expect(tokens.tag, childCardColorTokens(ChildCardColor.violet).tag);
    });
  });

  group('activityHubCardTokens', () {
    test('maps kinds to web palette', () {
      expect(
        activityHubCardTokens(ActivityHubKind.attendance).tag,
        childCardColorTokens(ChildCardColor.emerald).tag,
      );
      expect(
        activityHubCardTokens(ActivityHubKind.schedule).tag,
        profileHubCardTokens.tag,
      );
      expect(
        activityHubCardTokens(ActivityHubKind.payments).tag,
        childCardColorTokens(ChildCardColor.orange).tag,
      );
    });
  });

  group('homeworkHubCardTokens', () {
    test('uses orange tokens', () {
      final tokens = homeworkHubCardTokens();
      expect(tokens.tag, childCardColorTokens(ChildCardColor.orange).tag);
    });
  });

  group('homeworkAssignmentCardTokens', () {
    test('maps display status to band colors', () {
      expect(
        homeworkAssignmentCardTokens('overdue').tag,
        childCardColorTokens(ChildCardColor.rose).tag,
      );
      expect(
        homeworkAssignmentCardTokens('completed').tag,
        childCardColorTokens(ChildCardColor.emerald).tag,
      );
      expect(
        homeworkAssignmentCardTokens('in_progress').tag,
        profileHubCardTokens.tag,
      );
      expect(
        homeworkAssignmentCardTokens('assigned').tag,
        childCardColorTokens(ChildCardColor.sky).tag,
      );
    });
  });

  group('resolveDirectionHubCardColor', () {
    test('maps known slugs', () {
      expect(resolveDirectionHubCardColor('chtenie'), ChildCardColor.sky);
      expect(resolveDirectionHubCardColor('pismo'), ChildCardColor.violet);
      expect(resolveDirectionHubCardColor('matematika'), ChildCardColor.emerald);
    });

    test('matches slug fragments', () {
      expect(resolveDirectionHubCardColor('custom-reading-track'), ChildCardColor.sky);
      expect(resolveDirectionHubCardColor('my-writing'), ChildCardColor.violet);
    });

    test('falls back to sortOrder palette', () {
      expect(
        resolveDirectionHubCardColor('unknown', sortOrder: 1),
        childCardColors[1],
      );
    });
  });

  group('resolveDirectionHubIconKind', () {
    test('maps known slugs to icons', () {
      expect(resolveDirectionHubIconKind('chtenie'), HubCardIconKind.reading);
      expect(resolveDirectionHubIconKind('pismo'), HubCardIconKind.writing);
      expect(resolveDirectionHubIconKind('math'), HubCardIconKind.math);
      expect(resolveDirectionHubIconKind('other'), HubCardIconKind.direction);
    });
  });
}
