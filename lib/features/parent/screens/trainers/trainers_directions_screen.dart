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

/// Список направлений тренажёров — web `/parent/:childId/trainers`.
class TrainersDirectionsScreen extends StatefulWidget {
  const TrainersDirectionsScreen({super.key, required this.childId});

  final String childId;

  @override
  State<TrainersDirectionsScreen> createState() => _TrainersDirectionsScreenState();
}

class _TrainersDirectionsScreenState extends State<TrainersDirectionsScreen> {
  bool _isLoading = true;
  String? _error;
  String? _errorCode;
  ParentTrainerCatalogPage? _catalog;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
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
      setState(() {
        _catalog = catalog;
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
    return ParentScaffold(
      title: context.l10n.parentTrainersTitle,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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

    final groups = _catalog?.groups ?? const <ParentTrainerCatalogGroup>[];

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
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
              child: Text(
                l10n.parentTrainersEmpty,
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
                    for (var i = 0; i < groups.length; i++) ...[
                      if (i > 0) const SizedBox(height: ParentChildCardMetrics.pickerListGap),
                      StudyHubCard(
                        title: _catalog!.directionLabel(groups[i].direction),
                        tokens: trainerDirectionHubCardTokens(groups[i].direction),
                        icon: resolveTrainerDirectionHubIconKind(groups[i].direction),
                        onTap: () => ParentChildRoutes.pushForChild(
                          context,
                          childId: widget.childId,
                          segment: 'trainers/${groups[i].direction}',
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
