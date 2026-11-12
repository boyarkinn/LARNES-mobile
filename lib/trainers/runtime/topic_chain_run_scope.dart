import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_player_shell.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';
import 'topic_chain_run_state.dart';
import 'topic_chain_resume_store.dart';

class TopicChainRunScope extends InheritedWidget {
  const TopicChainRunScope({
    super.key,
    required this.controller,
    required super.child,
  });
  final TopicChainRunController controller;
  static TopicChainRunController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TopicChainRunScope>()
      ?.controller;
  @override
  bool updateShouldNotify(TopicChainRunScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Opens the durable launch before mounting the player/audio, then only advances
/// its parent after the terminal checkpoint has been acknowledged by the server.
class TopicChainRunGate extends StatefulWidget {
  const TopicChainRunGate({
    super.key,
    required this.runContext,
    required this.params,
    required this.builder,
    this.onComplete,
  });
  final Map<String, dynamic> runContext, params;
  final VoidCallback? onComplete;
  final Widget Function(
    Map<String, dynamic> params,
    Map<String, dynamic> snapshot,
    ExerciseAudioManifest? audio,
    VoidCallback onComplete,
  )
  builder;
  @override
  State<TopicChainRunGate> createState() => _TopicChainRunGateState();
}

class _TopicChainRunGateState extends State<TopicChainRunGate> {
  TopicChainRunController? _controller;
  bool _completing = false, _delivered = false, _opened = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final auth = AuthScope.of(context);
    final controller = TopicChainRunController(
      request: auth.parentApi.topicChainRuns.request,
      context: widget.runContext,
      params: widget.runContext['source'] == 'direct' ? widget.params : null,
      ownerId: auth.user!.id,
      locale: LocaleScope.read(context).localeCode,
    );
    _controller = controller;
    controller.addListener(_changed);
    unawaited(
      controller
          .open()
          .then((_) => _rememberDestination())
          .catchError((Object _) {}),
    );
  }

  Future<void> _rememberDestination() async {
    final controller = _controller!;
    if (!mounted) return;
    final auth = AuthScope.of(context);
    bool isCurrent() => mounted && auth.user?.id == controller.ownerId;
    if (!isCurrent()) return;
    try {
      if (controller.run?['completed'] == true ||
          controller.state['${topicChainStatePrefix}phase'] == 'complete') {
        await TopicChainResumeStore.clear(
          controller.ownerId,
          context: controller.context,
        );
      } else {
        await TopicChainResumeStore.remember(
          controller.ownerId,
          controller.context,
          isCurrent: isCurrent,
        );
      }
    } catch (_) {
      /* Navigation hint availability does not change the durable result. */
    }
    if (mounted) setState(() => _opened = true);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _complete() async {
    if (_completing || _delivered) return;
    _completing = true;
    try {
      await _controller!.flush();
      if (mounted && !_controller!.failed) {
        try {
          await TopicChainResumeStore.clear(
            _controller!.ownerId,
            context: _controller!.context,
          );
        } catch (_) {
          // An optional navigation hint cannot block an acknowledged result.
        }
        if (!mounted) return;
        _delivered = true;
        widget.onComplete?.call();
      }
    } catch (_) {
      // Pending command remains scoped to this authenticated launch for retry.
    } finally {
      _completing = false;
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_changed);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null ||
        !controller.failed && (!controller.ready || !_opened)) {
      return const ParentPlayerLoading();
    }
    if (controller.failed) {
      return ParentPlayerError(
        message: context.l10n.parentHomeworkPlayAdvanceFailed,
        retryLabel: context.l10n.catalogAudioRetry,
        onRetry: () {
          unawaited(
            controller
                .retry()
                .then((_) async {
                  await _rememberDestination();
                  if (controller.state['${topicChainStatePrefix}phase'] ==
                      'complete') {
                    unawaited(_complete());
                  }
                })
                .catchError((Object _) {}),
          );
        },
      );
    }
    final run = controller.run!;
    return TopicChainRunScope(
      controller: controller,
      child: KeyedSubtree(
        key: ValueKey('${run['id']}:${controller.generation}'),
        child: widget.builder(
          Map<String, dynamic>.from(run['params'] as Map),
          Map<String, dynamic>.from(run['runtimeSnapshot'] as Map),
          ExerciseAudioManifest.fromJson(run['audioManifest']),
          () => unawaited(_complete()),
        ),
      ),
    );
  }
}
