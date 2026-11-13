import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/features/parent/trainers/parent_trainer_play_session.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_player_shell.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_shell.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_step_chrome.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';
import 'package:larnes_mobile/trainers/runtime/topic_chain_run_scope.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/trainers/runtime/topic_chain_resume_store.dart';

/// Self-play тренажёра — web `/parent/:childId/trainers/play/:trainerKey`.
class TrainerPlayScreen extends StatefulWidget {
  const TrainerPlayScreen({
    super.key,
    required this.childId,
    required this.trainerKey,
  });

  final String childId;
  final String trainerKey;

  @override
  State<TrainerPlayScreen> createState() => _TrainerPlayScreenState();
}

class _TrainerPlayScreenState extends State<TrainerPlayScreen> {
  bool _isLoading = true;
  ParentTrainerPlaySession? _session;
  Map<String, dynamic>? _params;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bootstrap();
      }
    });
  }

  String _paramsPath() {
    final definition = getTrainerDefinition(widget.trainerKey);
    final direction = definition?.direction.name ?? 'mental';
    return '/parent/${widget.childId}/trainers/$direction/${widget.trainerKey}';
  }

  Future<void> _bootstrap() async {
    final session = await ParentTrainerPlaySessionStore.read(widget.trainerKey);
    if (!mounted) {
      return;
    }

    if (session == null) {
      context.go(_paramsPath());
      return;
    }

    final validated = validateTrainerParams(widget.trainerKey, {
      ...session.params,
      '__runtimeSnapshot': ?session.runtimeSnapshot,
    });
    if (!validated.ok || validated.params == null) {
      context.go(_paramsPath());
      return;
    }

    setState(() {
      _session = session;
      _params = validated.params;
      _isLoading = false;
    });
  }

  Future<void> _returnToParams() async {
    final owner = AuthScope.of(context).user?.id;
    if (owner != null && widget.trainerKey == 'topic-chain-flash') {
      try {
        await TopicChainResumeStore.clear(
          owner,
          context: {'source': 'direct', 'childId': widget.childId},
        );
      } catch (_) {
        // An optional navigation hint cannot prevent explicit exit.
      }
      if (!mounted) return;
    }
    final returnPath = _session?.returnPath;
    if (returnPath != null &&
        ParentTrainerPlaySessionStore.isValidReturnPath(returnPath)) {
      context.go(returnPath);
      return;
    }
    context.go(_paramsPath());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _returnToParams();
      },
      child: _buildContent(context.l10n),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_isLoading || _params == null) {
      return const ParentPlayerLoading();
    }

    final isInteractive = isTrainerInteractive(widget.trainerKey);

    Widget player(
      Map<String, dynamic> params,
      Map<String, dynamic>? snapshot,
      ExerciseAudioManifest? audio,
      VoidCallback? onComplete,
    ) => TrainerPlayer(
      key: ValueKey(widget.trainerKey),
      trainerKey: widget.trainerKey,
      params: params,
      resultContext: widget.trainerKey == 'reading-word-columns' && _session?.launchId != null ? {'source':'direct','childId':widget.childId,'launchId':_session!.launchId} : null,
      runtimeSnapshot: snapshot,
      audioManifest: audio,
      l10n: l10n,
      onComplete: onComplete,
      stepChrome: TrainerStepChrome(
        finishLabel: l10n.parentTrainersPlayFinish,
        isInteractive: isInteractive,
        isLast: true,
        nextLabel: l10n.parentTrainersPlayNext,
        onAdvance: _returnToParams,
      ),
    );

    return TrainerPlayShell(
      currentStep: 1,
      totalSteps: 1,
      menuContinueLabel: l10n.parentTrainersPlayMenuContinue,
      menuExitLabel: l10n.parentTrainersPlayExit,
      onExit: _returnToParams,
      child: widget.trainerKey == 'topic-chain-flash'
          ? TopicChainRunGate(
              runContext: {
                'source': 'direct',
                'childId': widget.childId,
                'launchId': _session!.launchId,
              },
              params: _params!,
              onComplete: _returnToParams,
              builder: (params, snapshot, audio, complete) =>
                  player(params, snapshot, audio, complete),
            )
          : player(
              _params!,
              _session?.runtimeSnapshot,
              _session?.audioManifest,
              isInteractive ? _returnToParams : null,
            ),
    );
  }
}
