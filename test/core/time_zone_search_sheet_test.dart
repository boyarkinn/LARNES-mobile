import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/time_zone_search_api.dart';
import 'package:larnes_mobile/core/time/time_zone_search_sheet.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;

class _FakeTimeZoneSearchApi extends TimeZoneSearchApi {
  _FakeTimeZoneSearchApi() : super(ApiClient());

  final queries = <String>[];
  final requests = <CancelToken?>[];
  final suggestions = <String, Completer<List<TimeZonePlaceSuggestion>>>{};
  final resolutions = <String, Completer<ResolvedTimeZonePlace>>{};

  @override
  Future<List<TimeZonePlaceSuggestion>> suggest({
    required String query,
    required String locale,
    CancelToken? cancelToken,
  }) {
    queries.add(query);
    requests.add(cancelToken);
    return (suggestions[query] ??= Completer()).future;
  }

  @override
  Future<ResolvedTimeZonePlace> resolve({
    required String mapboxId,
    required String locale,
    CancelToken? cancelToken,
  }) {
    requests.add(cancelToken);
    return (resolutions[mapboxId] ??= Completer()).future;
  }
}

const _chelyabinsk = TimeZonePlaceSuggestion(
  mapboxId: 'city-chelyabinsk',
  shortLabel: 'Челябинск',
  label: 'Челябинск, Россия',
);
const _london = TimeZonePlaceSuggestion(
  mapboxId: 'city-london',
  shortLabel: 'London',
  label: 'London, United Kingdom',
  timeZone: 'Europe/London',
);

Future<void> _open(
  WidgetTester tester,
  _FakeTimeZoneSearchApi api, {
  String locale = 'ru',
  void Function(String?)? selected,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => selected?.call(
              await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => TimeZoneSearchSheet(
                  api: api,
                  currentTimeZone: 'Asia/Tbilisi',
                  locale: locale,
                ),
              ),
            ),
            child: const Text('Open picker'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open picker'));
  await tester.pumpAndSettle();
}

Future<void> _query(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(const Duration(milliseconds: 301));
}

void main() {
  setUpAll(tz.initializeTimeZones);

  testWidgets(
    'debounces city search and ignores stale suggestions and resolutions',
    (tester) async {
      final api = _FakeTimeZoneSearchApi();
      String? chosen;
      await _open(tester, api, selected: (value) => chosen = value);
      await tester.enterText(find.byType(TextField), 'Че');
      await tester.pump(const Duration(milliseconds: 150));
      await _query(tester, 'Челябинск');
      expect(api.queries, ['Челябинск']);
      await _query(tester, 'London');
      expect(api.requests.first!.isCancelled, isTrue);
      api.suggestions['Челябинск']!.complete([_chelyabinsk]);
      api.suggestions['London']!.complete([_london]);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('time-zone-place-city-chelyabinsk')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('time-zone-place-city-london')),
      );
      await tester.pump();
      expect(
        chosen,
        isNull,
        reason: 'a city suggestion does not commit its unverified zone',
      );
      await _query(tester, 'Челябинск');
      api.resolutions['city-london']!.complete(
        const ResolvedTimeZonePlace(
          mapboxId: 'city-london',
          label: 'London',
          timeZone: 'Europe/London',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        chosen,
        isNull,
        reason: 'an old resolution cannot close the new search',
      );
      await tester.tap(
        find.byKey(const ValueKey('time-zone-place-city-chelyabinsk')),
      );
      await tester.pump();
      api.resolutions['city-chelyabinsk']!.complete(
        const ResolvedTimeZonePlace(
          mapboxId: 'city-chelyabinsk',
          label: 'Челябинск',
          timeZone: 'Asia/Yekaterinburg',
        ),
      );
      await tester.pumpAndSettle();
      expect(chosen, 'Asia/Yekaterinburg');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'city failures keep IANA fallback available and cancellation is safe',
    (tester) async {
      final api = _FakeTimeZoneSearchApi();
      String? chosen;
      await _open(
        tester,
        api,
        locale: 'en',
        selected: (value) => chosen = value,
      );
      await _query(tester, 'London');
      api.suggestions['London']!.completeError(
        const TimeZoneSearchException('upstream'),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('City search is unavailable'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('time-zone-iana-Europe/London')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('time-zone-iana-Europe/London')),
      );
      await tester.pumpAndSettle();
      expect(chosen, 'Europe/London');
      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();
      await _query(tester, 'Tbilisi');
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      api.suggestions['Tbilisi']!.complete([_london]);
      await tester.pumpAndSettle();
      expect(api.requests.last!.isCancelled, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'a failed or unsupported city zone never selects a previous zone',
    (tester) async {
      final api = _FakeTimeZoneSearchApi();
      String? chosen;
      await _open(tester, api, selected: (value) => chosen = value);
      await _query(tester, 'Челябинск');
      api.suggestions['Челябинск']!.complete([_chelyabinsk]);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('time-zone-place-city-chelyabinsk')),
      );
      await tester.pump();
      api.resolutions['city-chelyabinsk']!.complete(
        const ResolvedTimeZonePlace(
          mapboxId: 'city-chelyabinsk',
          label: 'Челябинск',
          timeZone: 'Invalid/Unknown',
        ),
      );
      await tester.pumpAndSettle();
      expect(chosen, isNull);
      expect(
        find.textContaining('Не удалось определить пояс города'),
        findsOneWidget,
      );
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
