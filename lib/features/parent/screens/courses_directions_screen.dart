import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/api/parent_panel_error.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_program.dart';
import 'package:larnes_mobile/features/parent/navigation/parent_child_routes.dart';
import 'package:larnes_mobile/features/parent/theme/hub_card_appearance.dart';
import 'package:larnes_mobile/features/parent/utils/family_setup_guard.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_panel_error_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/features/parent/widgets/study_hub_card.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Список направлений LARNES — web `/parent/:childId/courses`.
class CoursesDirectionsScreen extends StatefulWidget {
  const CoursesDirectionsScreen({super.key, required this.childId});

  final String childId;

  @override
  State<CoursesDirectionsScreen> createState() => _CoursesDirectionsScreenState();
}

class _CoursesDirectionsScreenState extends State<CoursesDirectionsScreen> {
  bool _isLoading = true;
  String? _error;
  String? _errorCode;
  List<ParentDirectionCard> _directions = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _errorCode = null;
    });

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
      title: l10n.parentCoursesTitle,
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

    if (_directions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.parentCoursesEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: ParentColors.inkMuted,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ParentChildCardMetrics.pickerMaxWidth),
            child: Column(
              children: [
                for (var i = 0; i < _directions.length; i++) ...[
                  if (i > 0) const SizedBox(height: ParentChildCardMetrics.pickerListGap),
                  StudyHubCard(
                    title: _directions[i].directionTitle,
                    tokens: directionHubCardTokens(
                      _directions[i].directionSlug,
                      sortOrder: _directions[i].sortOrder,
                    ),
                    icon: resolveDirectionHubIconKind(_directions[i].directionSlug),
                    onTap: () => ParentChildRoutes.pushForChild(
                      context,
                      childId: widget.childId,
                      segment: 'directions/${_directions[i].directionId}',
                      extra: DirectionProgramsRouteExtra(
                        directionTitle: _directions[i].directionTitle,
                        directionSlug: _directions[i].directionSlug,
                        sortOrder: _directions[i].sortOrder,
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
