import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/api/parent_panel_error.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/features/parent/navigation/parent_child_routes.dart';
import 'package:larnes_mobile/features/parent/utils/family_setup_guard.dart';
import 'package:larnes_mobile/features/parent/widgets/activity/parent_activity_class_row.dart';
import 'package:larnes_mobile/features/parent/widgets/activity/parent_activity_place_dock.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_panel_error_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// L2 посещаемость — список классов + place dock.
class ParentAttendanceClassesScreen extends StatefulWidget {
  const ParentAttendanceClassesScreen({super.key, required this.childId});

  final String childId;

  @override
  State<ParentAttendanceClassesScreen> createState() => _ParentAttendanceClassesScreenState();
}

class _ParentAttendanceClassesScreenState extends State<ParentAttendanceClassesScreen> {
  bool _isLoading = true;
  String? _error;
  String? _errorCode;
  String _placeId = parentActivitySummaryPlaceId;
  List<ParentActivityPlace> _places = const [];
  List<ParentActivityClass> _classes = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load({String? placeId, bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
        _errorCode = null;
      });
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final api = AuthScope.of(context).parentApi;
      final resolvedPlace = placeId ?? _placeId;

      final contextPage = await api.fetchActivityContext(
        widget.childId,
        place: resolvedPlace,
        locale: locale,
      );
      final classesPage = await api.listAttendanceClasses(
        widget.childId,
        place: resolvedPlace,
        locale: locale,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _places = contextPage.places;
        _placeId = classesPage.placeId;
        _classes = classesPage.classes;
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

  Future<void> _reloadClasses(String placeId) async {
    if (_placeId == placeId) {
      return;
    }

    setState(() {
      _placeId = placeId;
      _isLoading = true;
      _error = null;
      _errorCode = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final classesPage = await AuthScope.of(context).parentApi.listAttendanceClasses(
        widget.childId,
        place: placeId,
        locale: locale,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _placeId = classesPage.placeId;
        _classes = classesPage.classes;
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

  Future<void> _openClass(ParentActivityClass item) async {
    await ParentChildRoutes.pushForChild<void>(
      context,
      childId: widget.childId,
      segment: 'activity/attendance/${item.groupId}',
      extra: _placeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ParentScaffold(
      title: context.l10n.parentActivityAttendance,
      subBar: _places.isEmpty
          ? null
          : ParentActivityPlaceDock(
              places: _places,
              activePlaceId: _placeId,
              onPlaceSelected: _reloadClasses,
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

    if (_classes.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(silent: true),
        color: ParentColors.shell,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 36),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 48),
              child: Text(
                l10n.parentActivityAttendanceEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ParentColors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      color: ParentColors.shell,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 36),
        itemCount: _classes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _classes[index];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 576),
              child: ParentActivityClassRow(
                item: item,
                onTap: () => _openClass(item),
              ),
            ),
          );
        },
      ),
    );
  }
}
