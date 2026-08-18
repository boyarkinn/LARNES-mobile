import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/core/auth/child_session_token_storage.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_route_state.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_scope.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.kioskSettingsUnbindConfirmTitle),
        content: Text(l10n.kioskSettingsUnbindConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.kioskSettingsUnbindCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.kioskSettingsUnbindConfirm),
          ),
        ],
      ),
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

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.kioskSettingsTitle),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: Text(l10n.continueButton),
              ),
            ],
          ),
        ),
      );
    }

    final device = _device;
    if (device == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.kioskSettingsPlacement,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  kioskDevicePlacementLine(device, l10n),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.kioskSettingsDeviceId,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  device.deviceId,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.kioskSettingsUnbindTitle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.kioskSettingsUnbindHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_exitError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _exitError!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isExiting ? null : () => _confirmExit(l10n),
                  child: Text(
                    _isExiting
                        ? l10n.kioskSettingsUnbinding
                        : l10n.kioskSettingsUnbindSubmit,
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
