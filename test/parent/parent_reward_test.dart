import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_reward.dart';
import 'package:larnes_mobile/features/parent/widgets/rewards/reward_shop_detail_body.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  group('ParentReward models', () {
    test('hides the hub when the shelf is not live', () {
      final hidden = ParentRewardShopsPage.fromJson({
        'shops': <dynamic>[],
        'visible': false,
      });
      final live = ParentRewardShopsPage.fromJson({
        'shops': [
          {
            'balancePoints': 3,
            'ownerKind': 'network',
            'shopId': 'shop-1',
            'title': 'Школа',
          },
        ],
        'visible': true,
      });

      expect(hidden.visible, isFalse);
      expect(live.visible, isTrue);
      expect(live.shops.single.balancePoints, 3);
    });

    test('reads claimable items and request statuses', () {
      final detail = ParentRewardShopDetail.fromJson({
        'balancePoints': 2,
        'shopId': 'shop-1',
        'title': 'Репетитор',
        'items': [
          {
            'canClaim': true,
            'costPoints': 1,
            'id': 'item-1',
            'imageUrl': null,
            'title': 'Мяч',
          },
          {
            'canClaim': false,
            'costPoints': 5,
            'id': 'item-2',
            'imageUrl': '',
            'title': 'Робот',
          },
        ],
        'claims': [
          {
            'createdAt': '2026-08-15T00:00:00.000Z',
            'id': 'claim-1',
            'itemTitle': 'Мяч',
            'pointsSpent': 1,
            'status': 'pending',
          },
          {
            'createdAt': '2026-08-14T00:00:00.000Z',
            'id': 'claim-2',
            'itemTitle': 'Книга',
            'pointsSpent': 2,
            'status': 'handed_over',
          },
          {
            'createdAt': '2026-08-13T00:00:00.000Z',
            'id': 'claim-3',
            'itemTitle': 'Кубик',
            'pointsSpent': 1,
            'status': 'cancelled',
          },
        ],
      });

      expect(detail.items.first.canClaim, isTrue);
      expect(detail.items.last.canClaim, isFalse);
      expect(detail.items.last.imageUrl, isNull);
      expect(detail.claims.map((claim) => claim.status).toList(), [
        ParentRewardClaimStatus.pending,
        ParentRewardClaimStatus.handedOver,
        ParentRewardClaimStatus.cancelled,
      ]);
    });
  });

  group('RewardShopDetailBody', () {
    Widget wrap(Widget child) {
      final localeController = LocaleController();
      return LocaleScope(
        localeController: localeController,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: Scaffold(
            body: SizedBox(width: 360, child: child),
          ),
        ),
      );
    }

    testWidgets('shows Get when larcoins cover the reward', (tester) async {
      String? claimedId;
      await tester.pumpWidget(
        wrap(
          RewardShopDetailBody(
            detail: const ParentRewardShopDetail(
              balancePoints: 2,
              claims: [],
              items: [
                ParentRewardItem(
                  canClaim: true,
                  costPoints: 1,
                  id: 'ball',
                  title: 'Мяч',
                ),
              ],
              shopId: 'shop-1',
              title: 'Школа',
            ),
            isClaiming: false,
            onClaim: (id) => claimedId = id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 ларкоина'), findsOneWidget);
      await tester.ensureVisible(find.text('Получить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Получить'));
      expect(claimedId, 'ball');
    });

    testWidgets('hides Get when larcoins are not enough', (tester) async {
      await tester.pumpWidget(
        wrap(
          RewardShopDetailBody(
            detail: const ParentRewardShopDetail(
              balancePoints: 2,
              claims: [],
              items: [
                ParentRewardItem(
                  canClaim: false,
                  costPoints: 5,
                  id: 'robot',
                  title: 'Робот',
                ),
              ],
              shopId: 'shop-1',
              title: 'Школа',
            ),
            isClaiming: false,
            onClaim: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Получить'), findsNothing);
      await tester.ensureVisible(find.text('Пока не хватает'));
      expect(find.text('Пока не хватает'), findsOneWidget);
    });

    testWidgets('shows waiting, handed over and cancelled statuses', (tester) async {
      await tester.pumpWidget(
        wrap(
          RewardShopDetailBody(
            detail: const ParentRewardShopDetail(
              balancePoints: 0,
              claims: [
                ParentRewardClaim(
                  createdAt: '2026-08-15T00:00:00.000Z',
                  id: 'c1',
                  itemTitle: 'Мяч',
                  pointsSpent: 1,
                  status: ParentRewardClaimStatus.pending,
                ),
                ParentRewardClaim(
                  createdAt: '2026-08-14T00:00:00.000Z',
                  id: 'c2',
                  itemTitle: 'Книга',
                  pointsSpent: 2,
                  status: ParentRewardClaimStatus.handedOver,
                ),
                ParentRewardClaim(
                  createdAt: '2026-08-13T00:00:00.000Z',
                  id: 'c3',
                  itemTitle: 'Кубик',
                  pointsSpent: 1,
                  status: ParentRewardClaimStatus.cancelled,
                ),
              ],
              items: [],
              shopId: 'shop-1',
              title: 'Школа',
            ),
            isClaiming: false,
            onClaim: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ждёт выдачи'), findsOneWidget);
      expect(find.text('Выдано'), findsOneWidget);
      expect(find.text('Отменено'), findsOneWidget);
      expect(find.textContaining('купить'), findsNothing);
      expect(find.textContaining('очки'), findsNothing);
    });
  });
}
