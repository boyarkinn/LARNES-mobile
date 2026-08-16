import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/core/api/child_session_api_client.dart';
import 'package:larnes_mobile/core/auth/child_session_token_storage.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_route_state.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_scope.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/features/kiosk/controllers/kiosk_session_controller.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_device_labels.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_device_placement.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_scan_error_message.dart';
import 'package:larnes_mobile/features/kiosk/widgets/kiosk_qr_scanner.dart';
import 'package:larnes_mobile/features/kiosk/widgets/kiosk_program_player_view.dart';
import 'package:larnes_mobile/features/kiosk/widgets/kiosk_trainer_player_view.dart';
import 'package:larnes_mobile/features/kiosk/widgets/kiosk_scan_result_view.dart';
import 'package:larnes_mobile/features/kiosk/widgets/kiosk_unplaced_screen.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_initial_mode.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class KioskShell extends StatefulWidget {
  const KioskShell({
    super.key,
    this.syncInterval = kioskSyncInterval,
    this.placementPollInterval = kioskPlacementPollInterval,
    this.mockScanner = false,
    this.childSessionTokenStorage,
    this.childSessionApiClient,
    this.onControllerReady,
  });

  final Duration syncInterval;
  final Duration placementPollInterval;
  final bool mockScanner;
  final ChildSessionTokenStorage? childSessionTokenStorage;
  final ChildSessionApiClient? childSessionApiClient;

  /// Widget tests: capture controller and drive [KioskSessionController.runSyncCycle].
  @visibleForTesting
  final void Function(KioskSessionController controller)? onControllerReady;

  @override
  State<KioskShell> createState() => _KioskShellState();
}

class _KioskShellState extends State<KioskShell> with WidgetsBindingObserver {
  late final ChildSessionTokenStorage _childSessionTokenStorage =
      widget.childSessionTokenStorage ?? ChildSessionTokenStorage();
  late final ChildSessionApiClient _childSessionApiClient =
      widget.childSessionApiClient ??
          ChildSessionApiClient(
            childSessionTokenStorage: _childSessionTokenStorage,
          );

  bool _isLoading = true;
  bool _isUnplaced = false;
  bool _unplacedPaused = false;
  String? _error;
  KioskSessionController? _controller;
  Timer? _unplacedHeartbeatTimer;
  Timer? _unplacedPlacementPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bootstrap();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopUnplacedTimers();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final paused = state != AppLifecycleState.resumed;
    if (_isUnplaced) {
      _unplacedPaused = paused;
      return;
    }
    _controller?.setPaused(paused);
  }

  void _stopUnplacedTimers() {
    _unplacedHeartbeatTimer?.cancel();
    _unplacedHeartbeatTimer = null;
    _unplacedPlacementPollTimer?.cancel();
    _unplacedPlacementPollTimer = null;
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final kioskScope = KioskScope.of(context);
    final kioskApi = kioskScope.kioskApiClient.kioskApi;

    try {
      final device = await kioskApi.getDeviceMe();
      if (!mounted) {
        return;
      }

      if (!isKioskDevicePlaced(device)) {
        _controller?.dispose();
        _controller = null;
        _stopUnplacedTimers();
        _startUnplacedWatch(kioskApi: kioskApi, kioskScope: kioskScope);
        setState(() {
          _isUnplaced = true;
          _isLoading = false;
        });
        return;
      }

      await _startPlacedSession(
        device: device,
        kioskApi: kioskApi,
        kioskScope: kioskScope,
      );
    } on KioskApiException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.statusCode == 401) {
        await _handleDeviceUnauthorized(kioskScope);
        return;
      }
      setState(() {
        _error = error.message;
        _isLoading = false;
        _isUnplaced = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.networkLoadFailed;
          _isLoading = false;
          _isUnplaced = false;
        });
      }
    }
  }

  Future<void> _startPlacedSession({
    required KioskDeviceContext device,
    required KioskApi kioskApi,
    required KioskRouteState kioskScope,
  }) async {
    _stopUnplacedTimers();
    _controller?.dispose();

    final controller = KioskSessionController(
      kioskApi: kioskApi,
      childSessionTokenStorage: _childSessionTokenStorage,
      deviceContext: device,
      syncInterval: widget.syncInterval,
      onDeviceUnauthorized: () {
        if (!mounted) {
          return;
        }
        _handleDeviceUnauthorized(kioskScope);
      },
    )..start();

    setState(() {
      _controller = controller;
      _isUnplaced = false;
      _isLoading = false;
      _error = null;
    });
    widget.onControllerReady?.call(controller);
  }

  void _startUnplacedWatch({
    required KioskApi kioskApi,
    required KioskRouteState kioskScope,
  }) {
    Future<void> tickHeartbeat() async {
      if (!mounted || _unplacedPaused) {
        return;
      }
      try {
        await kioskApi.heartbeat();
      } on KioskApiException catch (error) {
        if (!mounted) {
          return;
        }
        if (error.statusCode == 401) {
          await _handleDeviceUnauthorized(kioskScope);
        }
      } catch (_) {
        // retry on next tick
      }
    }

    Future<void> tickPlacementPoll() async {
      if (!mounted || _unplacedPaused) {
        return;
      }
      try {
        final device = await kioskApi.getDeviceMe();
        if (!mounted) {
          return;
        }
        if (isKioskDevicePlaced(device)) {
          await _startPlacedSession(
            device: device,
            kioskApi: kioskApi,
            kioskScope: kioskScope,
          );
        }
      } on KioskApiException catch (error) {
        if (!mounted) {
          return;
        }
        if (error.statusCode == 401) {
          await _handleDeviceUnauthorized(kioskScope);
        }
      } catch (_) {
        // retry on next tick
      }
    }

    unawaited(tickHeartbeat());
    _unplacedHeartbeatTimer = Timer.periodic(widget.syncInterval, (_) {
      unawaited(tickHeartbeat());
    });
    unawaited(tickPlacementPoll());
    _unplacedPlacementPollTimer = Timer.periodic(widget.placementPollInterval, (_) {
      unawaited(tickPlacementPoll());
    });
  }

  Future<void> _handleDeviceUnauthorized(KioskRouteState kioskScope) async {
    _stopUnplacedTimers();
    _controller?.dispose();
    _controller = null;
    await kioskScope.clearDeviceToken();
    if (mounted) {
      context.go(kioskLoginRedirect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return _buildScaffold(context);
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  bool _isFullscreenPlayerMode(KioskSessionMode? mode) {
    return mode == KioskSessionMode.play || mode == KioskSessionMode.trainer;
  }

  Widget _buildScaffold(BuildContext context) {
    final controller = _controller;
    final fullscreenPlayer = _isFullscreenPlayerMode(controller?.mode);
    final hideSettings = _isLoading ||
        _error != null ||
        _isUnplaced ||
        fullscreenPlayer;

    final body = Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(fullscreenPlayer ? 0 : 24),
            child: _buildBody(context),
          ),
        ),
        if (!hideSettings && controller != null)
          Positioned(
            top: 8,
            right: 8,
            child: TextButton(
              onPressed: () => context.push('/kiosk/settings'),
              child: Text(context.l10n.kioskIdleSettings),
            ),
          ),
      ],
    );

    return Scaffold(
      body: fullscreenPlayer ? body : SafeArea(child: body),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _bootstrap,
              child: Text(l10n.continueButton),
            ),
          ],
        ),
      );
    }

    if (_isUnplaced) {
      return KioskUnplacedScreen(
        onOpenSettings: () => context.push('/kiosk/settings'),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    final switchKey = switch (controller.mode) {
      KioskSessionMode.play =>
        '${controller.mode.name}-${controller.activeProgramId}',
      KioskSessionMode.trainer =>
        '${controller.mode.name}-${controller.trainerReloadToken}',
      _ => controller.mode.name,
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(
        key: ValueKey(switchKey),
        child: _buildModeContent(context, controller, l10n, theme),
      ),
    );
  }

  Widget _buildModeContent(
    BuildContext context,
    KioskSessionController controller,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    switch (controller.mode) {
      case KioskSessionMode.idle:
        return _KioskModeLayout(
          title: l10n.kioskIdleTitle,
          subtitle: l10n.kioskIdleSubtitle,
          placement: kioskDevicePlacementLine(controller.deviceContext, l10n),
          child: const SizedBox.shrink(),
        );
      case KioskSessionMode.scan:
        return _KioskModeLayout(
          title: l10n.kioskScanTitle,
          subtitle: l10n.kioskScanSubtitle,
          placement: kioskDevicePlacementLine(controller.deviceContext, l10n),
          child: KioskQrScanner(
            mockScanEnabled: widget.mockScanner,
            externalError: controller.scanErrorCode != null
                ? kioskScanErrorMessageFromApiCode(
                    l10n,
                    controller.scanErrorCode,
                  ) ?? controller.scanError
                : controller.scanError,
            onScan: (token) async {
              controller.clearScanError();
              await controller.submitScan(token);
            },
          ),
        );
      case KioskSessionMode.play:
        final programId = controller.activeProgramId;
        if (programId == null) {
          return const SizedBox.shrink();
        }

        return KioskProgramPlayerView(
          programId: programId,
          programApi: _childSessionApiClient.kioskProgramApi,
          childDisplayName: controller.scanResult?.childDisplayName,
          locale: Localizations.localeOf(context).languageCode,
        );
      case KioskSessionMode.trainer:
        final kioskScope = KioskScope.of(context);
        return KioskTrainerPlayerView(
          trainerApi: kioskScope.kioskApiClient.trainerApi,
          reloadToken: controller.trainerReloadToken,
          locale: Localizations.localeOf(context).languageCode,
          onExit: controller.exitTrainer,
        );
      case KioskSessionMode.result:
        final result = controller.scanResult;
        return _KioskModeLayout(
          title: l10n.kioskResultTitle,
          subtitle: null,
          placement: kioskDevicePlacementLine(controller.deviceContext, l10n),
          child: result == null
              ? const SizedBox.shrink()
              : KioskScanResultView(result: result),
        );
    }
  }
}

class _KioskModeLayout extends StatelessWidget {
  const _KioskModeLayout({
    required this.title,
    required this.subtitle,
    required this.placement,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final String placement;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          title,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ] else
          const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              placement,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 24),
        child,
        const Spacer(flex: 2),
      ],
    );
  }
}
