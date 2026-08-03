import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/features/parent/utils/family_setup_guard.dart';
import 'package:larnes_mobile/features/parent/widgets/activity/parent_activity_payment_legend.dart';
import 'package:larnes_mobile/features/parent/widgets/activity/parent_activity_place_dock.dart';
import 'package:larnes_mobile/features/parent/widgets/activity/parent_schedule_day_grid.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_panel_error_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// L2 график — read-only сетка одного дня.
class ParentScheduleDayScreen extends StatefulWidget {
  const ParentScheduleDayScreen({super.key, required this.childId});

  final String childId;

  @override
  State<ParentScheduleDayScreen> createState() => _ParentScheduleDayScreenState();
}

class _ParentScheduleDayScreenState extends State<ParentScheduleDayScreen> {
  bool _isLoading = true;
  String? _error;
  String? _errorCode;
  String _placeId = parentActivitySummaryPlaceId;
  List<ParentActivityPlace> _places = const [];
  ParentActivityScheduleDayPage? _page;
  String? _dateIso;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load({String? dateIso, String? placeId}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _errorCode = null;
    });

    if (placeId != null) {
      _placeId = placeId;
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final api = AuthScope.of(context).parentApi;

      final results = await Future.wait([
        api.fetchActivityContext(
          widget.childId,
          place: _placeId,
          locale: locale,
        ),
        api.fetchScheduleDay(
          widget.childId,
          date: dateIso ?? _dateIso,
          place: _placeId,
          locale: locale,
        ),
      ]);

      if (!mounted) {
        return;
      }

      final contextPage = results[0] as ParentActivityContextPage;
      final schedulePage = results[1] as ParentActivityScheduleDayPage;

      setState(() {
        _places = contextPage.places;
        _page = schedulePage;
        _dateIso = schedulePage.dateIso;
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

  Future<void> _reloadSchedule(String dateIso) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _errorCode = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final schedulePage = await AuthScope.of(context).parentApi.fetchScheduleDay(
        widget.childId,
        date: dateIso,
        place: _placeId,
        locale: locale,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _page = schedulePage;
        _dateIso = schedulePage.dateIso;
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
    _load(placeId: placeId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ParentScaffold(
      title: l10n.parentActivitySchedule,
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
          l10n.parentActivityScheduleNotFound,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: ParentColors.inkMuted,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ParentScheduleDayGrid(
            page: page,
            l10n: l10n,
            onPrevDay: () => _reloadSchedule(page.prevDateIso),
            onNextDay: () => _reloadSchedule(page.nextDateIso),
          ),
        ),
        ParentActivityPaymentLegend(
          l10n: l10n,
          showMakeupLegend: page.showMakeupLegend,
        ),
      ],
    );
  }
}
