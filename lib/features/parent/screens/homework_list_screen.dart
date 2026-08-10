import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/navigation/parent_child_routes.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
import 'package:larnes_mobile/features/parent/utils/child_display.dart';
import 'package:larnes_mobile/features/parent/utils/homework_display.dart';
import 'package:larnes_mobile/features/parent/widgets/homework/homework_assignment_card.dart';
import 'package:larnes_mobile/features/parent/widgets/homework/homework_list_tabs.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class HomeworkListScreen extends StatefulWidget {
  const HomeworkListScreen({super.key, required this.childId});

  final String childId;

  @override
  State<HomeworkListScreen> createState() => _HomeworkListScreenState();
}

class _HomeworkListScreenState extends State<HomeworkListScreen> {
  bool _isLoading = true;
  String? _error;
  ParentHomeworkTab _activeTab = ParentHomeworkTab.due;
  ParentHomeworkListPage? _page;
  String _childTitle = '';

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
      });
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final api = AuthScope.of(context).parentApi;

      final results = await Future.wait([
        api.listHomework(widget.childId, tab: _activeTab, locale: locale),
        if (_childTitle.isEmpty) api.fetchChild(widget.childId, locale: locale),
      ]);

      if (!mounted) {
        return;
      }

      final page = results[0] as ParentHomeworkListPage;
      if (_childTitle.isEmpty && results.length > 1) {
        final detail = results[1] as ParentChildDetail;
        _childTitle = childHubHeaderTitle(detail.child);
      }

      setState(() {
        _page = page;
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
          _error = context.l10n.parentHomeworkLoadFailed;
          _isLoading = false;
        });
      }
    }
  }

  void _selectTab(ParentHomeworkTab tab) {
    if (_activeTab == tab) {
      return;
    }
    setState(() => _activeTab = tab);
    _load(silent: _page != null);
  }

  Future<void> _openAssignment(String assignmentId) async {
    final completed = await ParentChildRoutes.pushForChild<bool>(
      context,
      childId: widget.childId,
      segment: 'homework/$assignmentId',
    );

    if (!mounted) {
      return;
    }

    if (completed == true) {
      setState(() => _activeTab = ParentHomeworkTab.completed);
    }

    await _load(silent: _page != null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = _childTitle.isEmpty
        ? l10n.parentHomeworkTitle
        : l10n.parentHomeworkListTitle(_childTitle);

    return ParentScaffold(
      title: title,
      subBar: HomeworkListTabs(
        activeTab: _activeTab,
        counts: _page?.counts ?? const {},
        onTabSelected: _selectTab,
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(dynamic l10n) {
    if (_isLoading && _page == null) {
      return const Center(
        child: CircularProgressIndicator(color: ParentColors.shell),
      );
    }

    if (_error != null && _page == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: ParentColors.shell),
                onPressed: _load,
                child: Text(l10n.continueButton),
              ),
            ],
          ),
        ),
      );
    }

    final page = _page!;
    final assignments = page.assignments;

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      color: ParentColors.shell,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: LinearProgressIndicator(color: ParentColors.shell),
            ),
          const SizedBox(height: 16),
          if (assignments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
              child: Text(
                homeworkEmptyMessage(l10n, _activeTab),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
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
                    for (var i = 0; i < assignments.length; i++) ...[
                      if (i > 0) const SizedBox(height: ParentChildCardMetrics.pickerListGap),
                      HomeworkAssignmentCard(
                        assignment: assignments[i],
                        onTap: () => _openAssignment(assignments[i].assignmentId),
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
