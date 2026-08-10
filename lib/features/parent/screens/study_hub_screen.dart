import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/theme/hub_card_appearance.dart';
import 'package:larnes_mobile/features/parent/navigation/parent_child_routes.dart';
import 'package:larnes_mobile/features/parent/utils/child_display.dart';
import 'package:larnes_mobile/features/parent/utils/family_setup_guard.dart';
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
  bool _hasPublishedCourses = false;
  String _childFirstName = '';
  bool _wasInactive = false;

  static const _activityKinds = ActivityHubKind.values;

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
      });
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final parentApi = AuthScope.of(context).parentApi;
      final results = await Future.wait<Object?>([
        parentApi.hasPublishedLarnesCourses(locale: locale),
        parentApi.fetchChild(widget.childId, locale: locale),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _hasPublishedCourses = results[0]! as bool;
        _childFirstName = childHubHeaderTitle((results[1]! as ParentChildDetail).child);
        _isLoading = false;
      });
    } on ParentApiException catch (_) {
      if (mounted) {
        setState(() {
          _hasPublishedCourses = false;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasPublishedCourses = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ParentScaffold(
      title: _childFirstName,
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
                if (_hasPublishedCourses) ...[
                  const SizedBox(height: ParentChildCardMetrics.pickerListGap),
                  StudyHubCard(
                    title: l10n.parentStudyCoursesCard,
                    tokens: coursesHubCardTokens(),
                    icon: HubCardIconKind.courses,
                    onTap: () => ParentChildRoutes.pushForChild(
                      context,
                      childId: widget.childId,
                      segment: 'courses',
                    ),
                  ),
                ],
                for (final kind in _activityKinds) ...[
                  const SizedBox(height: ParentChildCardMetrics.pickerListGap),
                  StudyHubCard(
                    title: kind.title(l10n),
                    tokens: activityHubCardTokens(kind),
                    icon: activityHubIconKind(kind),
                    onTap: () => ParentChildRoutes.pushForChild(
                      context,
                      childId: widget.childId,
                      segment: 'activity/${kind.name}',
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
