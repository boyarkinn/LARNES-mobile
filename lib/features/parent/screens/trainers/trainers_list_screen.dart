import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_trainer_catalog.dart';
import 'package:larnes_mobile/features/parent/navigation/parent_child_routes.dart';
import 'package:larnes_mobile/features/parent/theme/hub_card_appearance.dart';
import 'package:larnes_mobile/features/parent/utils/family_setup_guard.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_panel_error_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/features/parent/widgets/study_hub_card.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Тренажёры направления — web `/parent/:childId/trainers/:direction`.
class TrainersListScreen extends StatefulWidget {
  const TrainersListScreen({
    super.key,
    required this.childId,
    required this.direction,
  });

  final String childId;
  final String direction;

  @override
  State<TrainersListScreen> createState() => _TrainersListScreenState();
}

class _TrainersListScreenState extends State<TrainersListScreen> {
  bool _isLoading = true;
  String? _error;
  String? _errorCode;
  ParentTrainerCatalogPage? _catalog;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (!isTrainerDirectionSlug(widget.direction)) {
          setState(() {
            _error = context.l10n.parentTrainersInvalidDirection;
            _isLoading = false;
          });
          return;
        }
        _load();
      }
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
        _errorCode = null;
      });
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final catalog = await AuthScope.of(context).parentApi.fetchTrainerCatalog(
        widget.childId,
        locale: locale,
      );
      if (!mounted) {
        return;
      }

      final group = catalog.groupForDirection(widget.direction);
      if (group == null) {
        setState(() {
          _catalog = catalog;
          _error = context.l10n.parentTrainersInvalidDirection;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _catalog = catalog;
        _error = null;
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
          _error = context.l10n.parentTrainersLoadFailed;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final directionLabel = _catalog?.directionLabel(widget.direction) ?? widget.direction;

    return ParentScaffold(
      title: directionLabel,
      body: _buildBody(directionLabel),
    );
  }

  Widget _buildBody(String directionLabel) {
    final l10n = context.l10n;

    if (_isLoading && _catalog == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _catalog == null) {
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

    if (_error != null && _catalog != null) {
      return Center(
        child: ParentPanelErrorPanel(
          message: _error!,
          onRetry: _load,
        ),
      );
    }

    final trainers = _catalog?.groupForDirection(widget.direction)?.trainers ??
        const <ParentTrainerCatalogItem>[];

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      color: ParentColors.shell,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 36),
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(color: ParentColors.shell),
            ),
          if (trainers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
              child: Text(
                l10n.parentTrainersEmptyTrainersTitle(directionLabel),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ParentColors.inkMuted,
                ),
              ),
            )
          else
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: ParentChildCardMetrics.pickerMaxWidth),
                child: Column(
                  children: [
                    for (var i = 0; i < trainers.length; i++) ...[
                      if (i > 0) const SizedBox(height: ParentChildCardMetrics.pickerListGap),
                      StudyHubCard(
                        title: trainers[i].title,
                        tokens: trainerDirectionHubCardTokens(widget.direction),
                        icon: resolveTrainerDirectionHubIconKind(widget.direction),
                        onTap: () => ParentChildRoutes.pushForChild(
                          context,
                          childId: widget.childId,
                          segment: 'trainers/${widget.direction}/${trainers[i].key}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
