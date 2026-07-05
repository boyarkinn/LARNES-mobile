import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/theme/child_avatar_catalog.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/widgets/account/child_education_profile.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

ParentChild _child() {
  return const ParentChild(
    id: 'c1',
    firstName: 'Иван',
    lastName: 'Иванов',
    cardColor: ChildCardColor.emerald,
    avatarSlug: ChildAvatarSlug.owl,
  );
}

void main() {
  Widget wrap(Widget child) {
    final localeController = LocaleController();
    return LocaleScope(
      localeController: localeController,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  testWidgets('tutor groups shown as comma-separated list', (tester) async {
    const education = ChildEducationContext(
      tutors: [
        ChildTutorContext(
          teacherId: 't1',
          teacherName: 'Педагог Тестовый',
          groups: [
            ChildTutorGroup(id: 'g1', name: 'ПН-СР 19:00'),
            ChildTutorGroup(id: 'g2', name: 'СБ 10:00'),
          ],
        ),
      ],
      networks: [],
    );

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return Column(
              children: childEducationProfileCards(
                context: context,
                child: _child(),
                education: education,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ПН-СР 19:00, СБ 10:00'), findsOneWidget);
  });
}
