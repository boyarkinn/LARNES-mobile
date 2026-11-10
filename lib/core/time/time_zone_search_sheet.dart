import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/time_zone_search_api.dart';
import 'package:larnes_mobile/core/time/time_zone_options.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:timezone/timezone.dart' as tz;

/// Returns a verified IANA zone as a local account draft. The account Save button commits it.
class TimeZoneSearchSheet extends StatefulWidget {
  const TimeZoneSearchSheet({
    super.key,
    required this.api,
    required this.currentTimeZone,
    required this.locale,
  });

  final TimeZoneSearchApi api;
  final String currentTimeZone;
  final String locale;

  @override
  State<TimeZoneSearchSheet> createState() => _TimeZoneSearchSheetState();
}

class _TimeZoneSearchSheetState extends State<TimeZoneSearchSheet> {
  Timer? _debounce;
  CancelToken? _request;
  int _generation = 0;
  String _query = '';
  List<TimeZonePlaceSuggestion> _places = [];
  bool _searching = false;
  bool _searchFailed = false;
  bool _resolveFailed = false;
  String? _resolvingId;
  late List<String> _zones;

  @override
  void initState() {
    super.initState();
    _zones = availableTimeZones(widget.currentTimeZone)
      ..sort(
        (a, b) => timeZoneLabel(
          a,
          widget.locale,
        ).compareTo(timeZoneLabel(b, widget.locale)),
      );
  }

  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
    _request?.cancel();
    super.dispose();
  }

  void _changeQuery(String value) {
    final query = value.trim();
    final generation = ++_generation;
    _debounce?.cancel();
    _request?.cancel();
    setState(() {
      _query = query;
      _places = [];
      _searchFailed = false;
      _resolveFailed = false;
      _resolvingId = null;
      _searching = query.length >= 2;
    });
    if (query.length < 2) return;
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _suggest(query, generation),
    );
  }

  Future<void> _suggest(String query, int generation) async {
    final request = CancelToken();
    _request = request;
    try {
      final places = await widget.api.suggest(
        query: query,
        locale: widget.locale,
        cancelToken: request,
      );
      if (mounted && generation == _generation) {
        setState(() {
          _places = places;
          _searching = false;
          _searchFailed = false;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _searching = false;
          _searchFailed = true;
        });
      }
    }
  }

  Future<void> _chooseCity(TimeZonePlaceSuggestion place) async {
    final generation = ++_generation;
    _debounce?.cancel();
    _request?.cancel();
    final request = CancelToken();
    _request = request;
    setState(() {
      _resolvingId = place.mapboxId;
      _searching = false;
      _resolveFailed = false;
    });
    try {
      // A suggestion may have no zone. Only a fresh successful resolution can be selected.
      final selection = await widget.api.resolve(
        mapboxId: place.mapboxId,
        locale: widget.locale,
        cancelToken: request,
      );
      if (!mounted || generation != _generation) return;
      if (!tz.timeZoneDatabase.locations.containsKey(selection.timeZone)) {
        throw const TimeZoneSearchException('unresolved');
      }
      Navigator.pop(context, selection.timeZone);
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _resolvingId = null;
          _resolveFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final matches = _zones
        .where(
          (zone) => '${timeZoneLabel(zone, widget.locale)} $zone'
              .toLowerCase()
              .contains(_query.toLowerCase()),
        )
        .toList();
    final heading = Theme.of(context).textTheme.labelLarge;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.timeZoneManual,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: l10n.timeZoneSearch,
                  prefixIcon: const Icon(Icons.search),
                  counterText: '',
                ),
                onChanged: _changeQuery,
              ),
            ),
            if (_searching) const LinearProgressIndicator(),
            Expanded(
              child: ListView(
                children: [
                  if (_query.length >= 2) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(l10n.timeZoneCities, style: heading),
                    ),
                    if (_searchFailed)
                      ListTile(
                        title: Text(l10n.timeZoneCitySearchError),
                        trailing: TextButton(
                          onPressed: () => _changeQuery(_query),
                          child: Text(l10n.messengerRetry),
                        ),
                      )
                    else if (!_searching && _places.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.timeZoneNoCities),
                      ),
                    for (final place in _places)
                      ListTile(
                        key: ValueKey('time-zone-place-${place.mapboxId}'),
                        title: Text(place.shortLabel),
                        subtitle: Text(
                          place.timeZone == null
                              ? place.label
                              : '${place.label} · ${timeZoneLabel(place.timeZone!, widget.locale)}',
                        ),
                        trailing: _resolvingId == place.mapboxId
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.location_city_outlined),
                        onTap: _resolvingId != null
                            ? null
                            : () => _chooseCity(place),
                      ),
                    if (_resolveFailed)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.timeZoneCityResolveError,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(l10n.timeZoneIanaZones, style: heading),
                  ),
                  if (matches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.timeZoneNoZones),
                    ),
                  for (final zone in matches)
                    ListTile(
                      key: ValueKey('time-zone-iana-$zone'),
                      title: Text(timeZoneLabel(zone, widget.locale)),
                      subtitle: Text(zone),
                      trailing: zone == widget.currentTimeZone
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () {
                        _generation++;
                        _debounce?.cancel();
                        _request?.cancel();
                        Navigator.pop(context, zone);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
