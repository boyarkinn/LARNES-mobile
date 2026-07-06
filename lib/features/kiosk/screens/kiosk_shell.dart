import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/core/auth/child_session_token_storage.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_route_state.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_scope.dart';
import 'package:larnes_mobile/features/kiosk/controllers/kiosk_session_controller.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_device_labels.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_scan_error_message.dart';
import 'package:larnes_mobile/features/kiosk/widgets/kiosk_qr_scanner.dart';
import 'package:larnes_mobile/features/kiosk/widgets/kiosk_scan_result_view.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_initial_mode.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class KioskShell extends StatefulWidget {
  const KioskShell({
    super.key,
    this.syncInterval = kioskSyncInterval,
    this.mockScanner = false,
  });

  final Duration syncInterval;
  final bool mockScanner;

  @override
  State<KioskShell> createState() => _KioskShellState();
}

class _KioskShellState extends State<KioskShell> with WidgetsBindingObserver {
  final ChildSessionTokenStorage _childSessionTokenStorage =
      ChildSessionTokenStorage();

  bool _isLoading = true;
  String? _error;
  KioskSessionController? _controller;

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
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller?.setPaused(state != AppLifecycleState.resumed);
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
        _isLoading = false;
      });
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
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.networkLoadFailed;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDeviceUnauthorized(KioskRouteState kioskScope) async {
    await kioskScope.clearDeviceToken();
    if (mounted) {
      context.go('/kiosk/enroll');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildBody(context),
              ),
            ),
            if (!_isLoading && _error == null && _controller != null)
              Positioned(
                top: 8,
                right: 8,
                child: TextButton(
                  onPressed: () => context.push('/kiosk/settings'),
                  child: Text(context.l10n.kioskIdleSettings),
                ),
              ),
          ],
        ),
      ),
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

    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(controller.mode),
            child: _buildModeContent(context, controller, l10n, theme),
          ),
        );
      },
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
