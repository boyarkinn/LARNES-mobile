import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_program.dart';
import 'package:larnes_mobile/features/parent/widgets/homework_direction_card.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class DirectionProgramsScreen extends StatefulWidget {
  const DirectionProgramsScreen({
    super.key,
    required this.childId,
    required this.directionId,
    required this.directionTitle,
  });

  final String childId;
  final String directionId;
  final String directionTitle;

  @override
  State<DirectionProgramsScreen> createState() => _DirectionProgramsScreenState();
}

class _DirectionProgramsScreenState extends State<DirectionProgramsScreen> {
  bool _isLoading = true;
  String? _error;
  DirectionTrack? _track;

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
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final api = AuthScope.of(context).parentApi;
      final track = await api.fetchDirectionTrack(
        widget.childId,
        widget.directionId,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _track = track;
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

  String _activeCtaLabel(AppLocalizations l10n, DirectionTrack track) {
    return track.progressStatus == ParentProgramProgressStatus.inProgress
        ? l10n.parentProgramDirectionContinue
        : l10n.parentProgramDirectionStart;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final track = _track;

    return ParentScaffold(
      title: widget.directionTitle,
      backLabel: l10n.parentDirectionProgramsBack,
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
              : track == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      children: [
                        switch (track.kind) {
                          DirectionTrackKind.empty => Text(
                              l10n.parentDirectionProgramsEmpty,
                              textAlign: TextAlign.center,
                            ),
                          DirectionTrackKind.allCompleted => HomeworkDirectionCard(
                              title: l10n.parentProgramTrackCompleted,
                              subtitle: '',
                              onTap: null,
                            ),
                          DirectionTrackKind.active => HomeworkDirectionCard(
                              title: _activeCtaLabel(l10n, track),
                              subtitle: track.title ?? '',
                              onTap: track.programId == null
                                  ? null
                                  : () => context.push(
                                        '/parent/${widget.childId}/programs/${track.programId}',
                                      ),
                            ),
                        },
                      ],
                    ),
    );
  }
}
