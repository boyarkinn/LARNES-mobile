import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/models/parent_program.dart';
import 'package:larnes_mobile/features/parent/widgets/homework_direction_card.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
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
  int _homeworkCount = 0;
  List<ParentDirectionCard> _directions = const [];
  bool _wasInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
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
      });
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final api = AuthScope.of(context).parentApi;
      final results = await Future.wait([
        api.fetchChild(widget.childId, locale: locale),
        api.listDirections(widget.childId, locale: locale),
      ]);
      if (!mounted) {
        return;
      }
      final detail = results[0] as ParentChildDetail;
      final directions = results[1] as List<ParentDirectionCard>;
      setState(() {
        _homeworkCount = detail.homeworkCount;
        _directions = directions;
        _isLoading = false;
        _error = null;
      });
    } on ParentApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
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
    final subtitle = _homeworkCount > 0
        ? l10n.parentHomeworkAssignmentCount(_homeworkCount)
        : l10n.parentHomeworkEmptyHint;

    return ParentScaffold(
      title: l10n.parentStudyTitle,
      backLabel: l10n.parentBack,
      onBack: () => context.pop(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: Text(l10n.continueButton)),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    HomeworkDirectionCard(
                      title: l10n.parentHomeworkTitle,
                      subtitle: subtitle,
                      onTap: () => context.push('/parent/${widget.childId}/homework'),
                    ),
                    for (final direction in _directions) ...[
                      const SizedBox(height: 12),
                      HomeworkDirectionCard(
                        title: direction.directionTitle,
                        subtitle: l10n.parentLearningDirectionProgramCount(direction.programCount),
                        onTap: () => context.push(
                          '/parent/${widget.childId}/directions/${direction.directionId}',
                          extra: direction.directionTitle,
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
