import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/core/auth/child_session_token_storage.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_route_state.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_scope.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/theme/kiosk_theme.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_device_labels.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class KioskSettingsScreen extends StatefulWidget {
  const KioskSettingsScreen({
    super.key,
    this.childSessionTokenStorage,
  });

  final ChildSessionTokenStorage? childSessionTokenStorage;

  @override
  State<KioskSettingsScreen> createState() => _KioskSettingsScreenState();
}

class _KioskSettingsScreenState extends State<KioskSettingsScreen> {
  late final ChildSessionTokenStorage _childSessionTokenStorage =
      widget.childSessionTokenStorage ?? ChildSessionTokenStorage();

  bool _isLoading = true;
  bool _isExiting = false;
  String? _loadError;
  String? _exitError;
  KioskDeviceContext? _device;

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
      _loadError = null;
    });

    final kioskScope = KioskScope.of(context);
    final kioskApi = kioskScope.kioskApiClient.kioskApi;

    try {
      final device = await kioskApi.getDeviceMe();
      if (!mounted) {
        return;
      }
      setState(() {
        _device = device;
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
        _loadError = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = context.l10n.networkLoadFailed;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDeviceUnauthorized(KioskRouteState kioskScope) async {
    await kioskScope.clearDeviceToken();
    if (mounted) {
      context.go(defaultLoginRoute);
    }
  }

  Future<void> _confirmExit(AppLocalizations l10n) async {
    final confirmed = await showKioskConfirmDialog(
      context: context,
      title: l10n.kioskSettingsUnbindConfirmTitle,
      message: l10n.kioskSettingsUnbindConfirmMessage,
      cancelLabel: l10n.kioskSettingsUnbindCancel,
      confirmLabel: l10n.kioskSettingsUnbindConfirm,
    );

    if (confirmed == true && mounted) {
      await _exitDevice();
    }
  }

  Future<void> _exitDevice() async {
    if (_device == null || _isExiting) {
      return;
    }

    setState(() {
      _isExiting = true;
      _exitError = null;
    });

    final kioskScope = KioskScope.of(context);
    final kioskApi = kioskScope.kioskApiClient.kioskApi;

    try {
      final locale = LocaleScope.read(context).localeCode;
      try {
        await kioskApi.childLogout(locale: locale);
      } catch (_) {
        // best effort before device exit
      }

      await kioskApi.exitDevice(locale: locale);
      await kioskScope.clearDeviceToken();
      await _childSessionTokenStorage.clearToken();

      if (!mounted) {
        return;
      }

      context.go(defaultLoginRoute);
    } on KioskApiException catch (error) {
      if (mounted) {
        setState(() {
          _isExiting = false;
          _exitError = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isExiting = false;
          _exitError = context.l10n.requestFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return KioskHeroBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KioskPageHeader(title: l10n.kioskSettingsTitle),
            Expanded(child: _buildBody(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: KioskColors.blue),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: kioskPaperPanelDecoration(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: KioskColors.ink,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    KioskPrimaryButton(
                      label: l10n.continueButton,
                      onPressed: _load,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final device = _device;
    if (device == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: kioskPaperPanelDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.kioskSettingsPlacement,
                          style: kioskSectionLabelStyle(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          kioskDevicePlacementLine(device, l10n),
                          style: const TextStyle(
                            color: KioskColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.kioskSettingsDeviceId,
                          style: kioskSectionLabelStyle(),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          device.deviceId,
                          style: const TextStyle(
                            color: KioskColors.muted,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: kioskPaperPanelDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.kioskSettingsUnbindTitle,
                          style: const TextStyle(
                            color: KioskColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.kioskSettingsUnbindHint,
                          style: const TextStyle(
                            color: KioskColors.muted,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                        if (_exitError != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _exitError!,
                            style: const TextStyle(
                              color: Color(0xFFB42318),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        KioskSecondaryButton(
                          key: const Key('kiosk-settings-exit'),
                          label: _isExiting
                              ? l10n.kioskSettingsUnbinding
                              : l10n.kioskSettingsUnbindSubmit,
                          isLoading: _isExiting,
                          onPressed:
                              _isExiting ? null : () => _confirmExit(l10n),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
