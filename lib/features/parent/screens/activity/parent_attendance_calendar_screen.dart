import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/features/parent/utils/family_setup_guard.dart';
import 'package:larnes_mobile/features/parent/widgets/activity/parent_activity_place_dock.dart';
import 'package:larnes_mobile/features/parent/widgets/activity/parent_attendance_calendar_view.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_panel_error_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// L3 посещаемость — read-only календарь месяца.
class ParentAttendanceCalendarScreen extends StatefulWidget {
  const ParentAttendanceCalendarScreen({
    super.key,
    required this.childId,
    required this.groupId,
    this.placeId = parentActivitySummaryPlaceId,
  });

  final String childId;
  final String groupId;
  final String placeId;

  @override
  State<ParentAttendanceCalendarScreen> createState() => _ParentAttendanceCalendarScreenState();
}

class _ParentAttendanceCalendarScreenState extends State<ParentAttendanceCalendarScreen> {
  bool _isLoading = true;
  String? _error;
  String? _errorCode;
  String _placeId = parentActivitySummaryPlaceId;
  List<ParentActivityPlace> _places = const [];
  ParentAttendanceCalendarPage? _page;
  String? _monthKey;

  @override
  void initState() {
    super.initState();
    _placeId = widget.placeId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load({String? monthKey}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _errorCode = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final api = AuthScope.of(context).parentApi;

      final results = await Future.wait([
        api.fetchActivityContext(
          widget.childId,
          place: _placeId,
          locale: locale,
        ),
        api.fetchAttendanceCalendar(
          widget.childId,
          widget.groupId,
          month: monthKey ?? _monthKey,
          locale: locale,
        ),
      ]);

      if (!mounted) {
        return;
      }

      final contextPage = results[0] as ParentActivityContextPage;
      final calendarPage = results[1] as ParentAttendanceCalendarPage;

      setState(() {
        _places = contextPage.places;
        _page = calendarPage;
        _monthKey = calendarPage.monthKey;
        _isLoading = false;
      });
    } on ParentApiException catch (error) {
      if (mounted && redirectToFamilySetupIfRequired(context, code: error.code)) {
        return;
      }
      if (mounted) {
        setState(() {
          _error = error.message;
          _errorCode = error.code;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.parentActivityLoadFailed;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reloadCalendar(String monthKey) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _errorCode = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final calendarPage = await AuthScope.of(context).parentApi.fetchAttendanceCalendar(
        widget.childId,
        widget.groupId,
        month: monthKey,
        locale: locale,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _page = calendarPage;
        _monthKey = calendarPage.monthKey;
        _isLoading = false;
      });
    } on ParentApiException catch (error) {
      if (mounted && redirectToFamilySetupIfRequired(context, code: error.code)) {
        return;
      }
      if (mounted) {
        setState(() {
          _error = error.message;
          _errorCode = error.code;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.parentActivityLoadFailed;
          _isLoading = false;
        });
      }
    }
  }

  void _selectPlace(String placeId) {
    if (_placeId == placeId) {
      return;
    }
    setState(() => _placeId = placeId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groupName = _page?.groupName ?? '';
    final title = groupName.isEmpty
        ? l10n.parentActivityAttendance
        : l10n.parentActivityCalendarTitle(groupName);

    return ParentScaffold(
      title: title,
      subBar: _places.isEmpty
          ? null
          : ParentActivityPlaceDock(
              places: _places,
              activePlaceId: _placeId,
              onPlaceSelected: _selectPlace,
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: ParentPanelErrorPanel(
          message: _error!,
          showFamilySetupAction: isFamilySetupRequiredCode(_errorCode),
          onFamilySetup: () => redirectToFamilySetupIfRequired(
            context,
            code: _errorCode,
          ),
          onRetry: _load,
        ),
      );
    }

    final page = _page;
    if (page == null) {
      return Center(
        child: Text(
          l10n.parentActivityCalendarNotFound,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: ParentColors.inkMuted,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 576),
            child: ParentAttendanceCalendarView(
              page: page,
              l10n: l10n,
              onPrevMonth: page.prevMonthKey == null
                  ? null
                  : () => _reloadCalendar(page.prevMonthKey!),
              onNextMonth: page.nextMonthKey == null
                  ? null
                  : () => _reloadCalendar(page.nextMonthKey!),
            ),
          ),
        ),
      ],
    );
  }
}
