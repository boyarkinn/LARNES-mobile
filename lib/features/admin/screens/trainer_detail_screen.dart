import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/core/api/admin_trainers_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/admin/models/trainer_workflow.dart';
import 'package:larnes_mobile/features/admin/screens/trainer_play_panel.dart';
import 'package:larnes_mobile/features/admin/screens/trainer_workflow_panel.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_account_scaffold.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class TrainerDetailScreen extends StatefulWidget {
  const TrainerDetailScreen({super.key, required this.trainerKey});

  final String trainerKey;

  @override
  State<TrainerDetailScreen> createState() => _TrainerDetailScreenState();
}

class _TrainerDetailScreenState extends State<TrainerDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isLoading = true;
  String? _error;
  TrainerWorkflowDetail? _detail;

  TrainerSignoffStatus? _pendingSignoff;
  String? _pendingCommentId;
  TrainerDevCommentStatus? _pendingCommentStatus;
  bool _isSubmittingComment = false;
  String? _mutationError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isMutating =>
      _pendingSignoff != null || _pendingCommentId != null || _isSubmittingComment;

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final detail = await AuthScope.of(context).adminTrainersApi.fetchTrainerDetail(
            trainerKey: widget.trainerKey,
            locale: locale,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _detail = detail;
        _isLoading = false;
        _error = null;
      });
    } on AdminTrainersApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = context.l10n.adminTrainerWorkflowLoadFailed;
        _isLoading = false;
      });
    }
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    setState(() {
      _mutationError = null;
    });

    try {
      await action();
      await _load(silent: true);
    } on AdminTrainersApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _mutationError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _mutationError = context.l10n.requestFailed;
      });
    } finally {
      if (mounted) {
        setState(() {
          _pendingSignoff = null;
          _pendingCommentId = null;
          _pendingCommentStatus = null;
          _isSubmittingComment = false;
        });
      }
    }
  }

  Future<void> _handleSignoff(TrainerWorkflowPlatform platform, TrainerSignoffStatus status) async {
    setState(() {
      _pendingSignoff = status;
    });

    final locale = LocaleScope.read(context).localeCode;
    await _runMutation(() {
      return AuthScope.of(context).adminTrainersApi.updateSignoff(
            trainerKey: widget.trainerKey,
            platform: platform,
            signoffStatus: status,
            locale: locale,
          );
    });
  }

  Future<void> _handleCreateComment(TrainerWorkflowPlatform platform, String body) async {
    setState(() {
      _isSubmittingComment = true;
    });

    final locale = LocaleScope.read(context).localeCode;
    await _runMutation(() {
      return AuthScope.of(context).adminTrainersApi.createComment(
            trainerKey: widget.trainerKey,
            platform: platform,
            body: body,
            locale: locale,
          );
    });
  }

  Future<void> _handleUpdateCommentStatus(String commentId, TrainerDevCommentStatus status) async {
    setState(() {
      _pendingCommentId = commentId;
      _pendingCommentStatus = status;
    });

    final locale = LocaleScope.read(context).localeCode;
    await _runMutation(() {
      return AuthScope.of(context).adminTrainersApi.updateCommentStatus(
            commentId: commentId,
            status: status,
            locale: locale,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = _detail?.trainer.title ?? widget.trainerKey;

    return AdminAccountScaffold(
      title: title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_detail != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                '${_detail!.trainer.key} · ${_detail!.trainer.direction}',
                style: GoogleFonts.robotoMono(fontSize: 12, color: AdminColors.inkMuted),
              ),
            ),
          Material(
            color: AdminColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AdminColors.accent,
              unselectedLabelColor: AdminColors.inkMuted,
              indicatorColor: AdminColors.accent,
              tabs: [
                Tab(text: l10n.adminTrainerWorkflowTabWorkflow),
                Tab(text: l10n.adminTrainerWorkflowTabPlay),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.line),
          Expanded(child: _buildTabBody(l10n)),
        ],
      ),
    );
  }

  Widget _buildTabBody(AppLocalizations l10n) {
    if (_isLoading && _detail == null) {
      return const Center(child: CircularProgressIndicator(color: AdminColors.accent));
    }

    if (_error != null && _detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AdminColors.inkMuted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AdminColors.accent),
                onPressed: _load,
                child: Text(l10n.continueButton),
              ),
            ],
          ),
        ),
      );
    }

    final detail = _detail;
    if (detail == null) {
      return const SizedBox.shrink();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        RefreshIndicator(
          onRefresh: () => _load(silent: true),
          child: TrainerWorkflowPanel(
            detail: detail,
            l10n: l10n,
            onSignoff: _handleSignoff,
            onCreateComment: _handleCreateComment,
            onUpdateCommentStatus: _handleUpdateCommentStatus,
            pendingSignoff: _pendingSignoff,
            pendingCommentId: _pendingCommentId,
            pendingCommentStatus: _pendingCommentStatus,
            isSubmittingComment: _isSubmittingComment,
            isMutating: _isMutating,
            mutationError: _mutationError,
          ),
        ),
        TrainerPlayPanel(trainerKey: widget.trainerKey),
      ],
    );
  }
}
