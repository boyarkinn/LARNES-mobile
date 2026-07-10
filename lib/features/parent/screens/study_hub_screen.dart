import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/api/parent_panel_error.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_program.dart';
import 'package:larnes_mobile/features/parent/theme/hub_card_appearance.dart';
import 'package:larnes_mobile/features/parent/navigation/parent_child_routes.dart';
import 'package:larnes_mobile/features/parent/utils/family_setup_guard.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_panel_error_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/features/parent/widgets/study_hub_card.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class StudyHubScreen extends StatefulWidget {
  const StudyHubScreen({super.key, required this.childId});

  final String childId;

  @override
  State<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends State<StudyHubScreen> {
  bool _isLoading = true;
  String? _error;
  String? _errorCode;
  List<ParentDirectionCard> _directions = const [];
  bool _wasInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (isReservedParentChildRouteId(widget.childId)) {
        context.go('/parent/family-setup');
        return;
      }
      _load();
    });
  }

  @override
  void activate() {
    super.activate();
    if (_wasInactive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _load(refreshing: true);
        }
      });
    }
    _wasInactive = false;
  }

  @override
  void deactivate() {
    _wasInactive = true;
    super.deactivate();
  }

  Future<void> _load({bool refreshing = false}) async {
    if (!refreshing) {
      setState(() {
        _isLoading = true;
        _error = null;
        _errorCode = null;
      });
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final directions = await AuthScope.of(context).parentApi.listDirections(
        widget.childId,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _directions = directions;
        _isLoading = false;
        _error = null;
        _errorCode = null;
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
          _error = context.l10n.requestFailed;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ParentScaffold(
      title: l10n.parentStudyTitle,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ParentChildCardMetrics.pickerMaxWidth),
            child: Column(
              children: [
                StudyHubCard(
                  title: l10n.parentStudyProfileCard,
                  tokens: profileHubCardTokens,
                  icon: HubCardIconKind.profile,
                  onTap: () => ParentChildRoutes.pushForChild(
                    context,
                    childId: widget.childId,
                    segment: 'profile',
                  ),
                ),
                const SizedBox(height: ParentChildCardMetrics.pickerListGap),
                StudyHubCard(
                  title: l10n.parentHomeworkTitle,
                  tokens: homeworkHubCardTokens(),
                  icon: HubCardIconKind.homework,
                  onTap: () => ParentChildRoutes.pushForChild(
                    context,
                    childId: widget.childId,
                    segment: 'homework',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: ParentChildCardMetrics.pickerListGap),
                  ParentPanelErrorPanel(
                    message: _error!,
                    showFamilySetupAction: isFamilySetupRequiredCode(
                      _errorCode,
                    ),
                    onFamilySetup: () => redirectToFamilySetupIfRequired(
                      context,
                      code: _errorCode,
                    ),
                    onRetry: _load,
                  ),
                ],
                for (final direction in _directions) ...[
                  const SizedBox(height: ParentChildCardMetrics.pickerListGap),
                  StudyHubCard(
                    title: direction.directionTitle,
                    tokens: directionHubCardTokens(
                      direction.directionSlug,
                      sortOrder: direction.sortOrder,
                    ),
                    icon: resolveDirectionHubIconKind(direction.directionSlug),
                    onTap: () => ParentChildRoutes.pushForChild(
                      context,
                      childId: widget.childId,
                      segment: 'directions/${direction.directionId}',
                      extra: DirectionProgramsRouteExtra(
                        directionTitle: direction.directionTitle,
                        directionSlug: direction.directionSlug,
                        sortOrder: direction.sortOrder,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
