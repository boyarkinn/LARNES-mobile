import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/theme/child_avatar_catalog.dart';
import 'package:larnes_mobile/features/parent/widgets/child_avatar.dart';

void main() {
  group('resolveChildAvatarSlug', () {
    test('returns known slug', () {
      expect(resolveChildAvatarSlug('owl'), ChildAvatarSlug.owl);
    });

    test('falls back to fox for unknown slug', () {
      expect(resolveChildAvatarSlug('cat'), defaultChildAvatarSlug);
    });
  });

  group('childAvatarAssetPaths', () {
    test('maps every catalog slug to asset path', () {
      for (final slug in childAvatarSlugs) {
        expect(childAvatarAssetPaths[slug], isNotNull);
        expect(childAvatarAssetPaths[slug]!, endsWith('${slug.name}.svg'));
      }
    });
  });

  group('ChildAvatar', () {
    Widget wrap(Widget child) {
      return MaterialApp(home: Scaffold(body: Center(child: child)));
    }

    for (final slug in childAvatarSlugs) {
      testWidgets('renders $slug at requested size', (tester) async {
        await tester.pumpWidget(
          wrap(ChildAvatar(slug: slug, size: 36)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ChildAvatar), findsOneWidget);
        final size = tester.getSize(find.byType(ChildAvatar));
        expect(size.width, 36);
        expect(size.height, 36);
      });
    }

    testWidgets('fromString uses fallback slug asset', (tester) async {
      await tester.pumpWidget(
        wrap(ChildAvatar.fromString(slug: 'unknown', size: 40)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChildAvatar), findsOneWidget);
    });
  });
}
