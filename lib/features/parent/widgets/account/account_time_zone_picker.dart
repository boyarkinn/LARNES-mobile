import 'dart:async';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/time/user_time_zone.dart';
import 'package:larnes_mobile/core/time/time_zone_options.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AccountTimeZonePicker extends StatefulWidget {
  const AccountTimeZonePicker({super.key});
  @override
  State<AccountTimeZonePicker> createState() => _AccountTimeZonePickerState();
}

class _AccountTimeZonePickerState extends State<AccountTimeZonePicker> {
  late bool _auto;
  late String _zone;
  bool _pending = false;
  Timer? _clock;
  AuthSession? _session;
  String _profileKey = "";
  @override
  void initState() {
    super.initState();
    _auto = UserTimeZone.manualZone == null;
    _zone = UserTimeZone.effectiveZone ?? 'UTC';
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AuthScope.of(context);
    if (_session != session) {
      _session?.removeListener(_profileChanged);
      _session = session;
      session.addListener(_profileChanged);
    }
    _readProfile();
  }

  void _readProfile() {
    final user = _session?.user;
    final key = '${user?.id}|${user?.timeZone}|${user?.cityTimeZone}';
    if (key != _profileKey) {
      _profileKey = key;
      _auto = UserTimeZone.manualZone == null;
      _zone = UserTimeZone.effectiveZone ?? 'UTC';
    }
  }

  void _profileChanged() {
    if (mounted) setState(_readProfile);
  }

  @override
  void dispose() {
    _clock?.cancel();
    _session?.removeListener(_profileChanged);
    super.dispose();
  }

  Future<void> _choose() async {
    final l10n = context.l10n;
    final locale = LocaleScope.of(context).localeCode;
    var query = '';
    final zones = availableTimeZones(_zone)
      ..sort(
        (a, b) => timeZoneLabel(a, locale).compareTo(timeZoneLabel(b, locale)),
      );
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) {
          final matches = zones
              .where(
                (zone) => '${timeZoneLabel(zone, locale)} $zone'
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList();
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
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
                      decoration: InputDecoration(
                        labelText: l10n.timeZoneSearch,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) => update(() => query = value),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final zone = matches[index];
                        return ListTile(
                          title: Text(timeZoneLabel(zone, locale)),
                          subtitle: Text(zone),
                          trailing: zone == _zone
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () => Navigator.pop(context, zone),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (selected != null && mounted) setState(() => _zone = selected);
  }

  Future<void> _save() async {
    setState(() => _pending = true);
    try {
      await UserTimeZone.refreshDeviceZone();
      if (!_auto) tz.getLocation(_zone);
      if (!mounted) return;
      await AuthScope.of(
        context,
      ).saveTimeZone(automatic: _auto, timeZone: _auto ? null : _zone);
      if (mounted) {
        setState(() => _zone = UserTimeZone.effectiveZone ?? 'UTC');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.timeZoneSaved)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.timeZoneError)));
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = LocaleScope.of(context).localeCode;
    final user = AuthScope.of(context).user;
    final effective = UserTimeZone.effectiveZone;
    final now = UserTimeZone.displayTime(DateTime.now());
    final clock =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final source = UserTimeZone.manualZone != null
        ? l10n.timeZoneSourceManual
        : UserTimeZone.cityZone != null
        ? l10n.timeZoneSourceCity(user?.city ?? '')
        : l10n.timeZoneSourceDevice;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.timeZoneTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '$clock · ${effective == null ? l10n.timeZoneUnknown : timeZoneLabel(effective, locale)}',
          ),
          Text(source, style: Theme.of(context).textTheme.bodySmall),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.timeZoneAuto),
            value: _auto,
            onChanged: _pending
                ? null
                : (value) => setState(() => _auto = value),
          ),
          if (!_auto)
            OutlinedButton.icon(
              onPressed: _pending ? null : _choose,
              icon: const Icon(Icons.expand_more),
              label: Text(timeZoneLabel(_zone, locale)),
            ),
          const SizedBox(height: 8),
          Text(l10n.timeZoneHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _pending ? null : _save,
            child: Text(l10n.timeZoneSave),
          ),
        ],
      ),
    );
  }
}
