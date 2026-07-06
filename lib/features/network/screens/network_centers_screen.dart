import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/network_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/language_switcher.dart';
import 'package:larnes_mobile/features/network/models/network_center.dart';
import 'package:larnes_mobile/features/network/models/network_device.dart';
import 'package:larnes_mobile/features/network/widgets/network_center_tile.dart';
import 'package:larnes_mobile/features/network/widgets/network_device_tile.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class NetworkCentersScreen extends StatefulWidget {
  const NetworkCentersScreen({super.key});

  @override
  State<NetworkCentersScreen> createState() => _NetworkCentersScreenState();
}

class _NetworkCentersScreenState extends State<NetworkCentersScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  List<NetworkCenter> _centers = const [];
  List<NetworkDevice> _devices = const [];
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
          _load(refreshing: _centers.isNotEmpty || _devices.isNotEmpty);
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

  bool get _hasData => _centers.isNotEmpty || _devices.isNotEmpty;

  Future<void> _load({bool refreshing = false}) async {
    if (refreshing) {
      setState(() => _isRefreshing = true);
    } else if (!_hasData) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final api = AuthScope.of(context).networkApi;
      final results = await Future.wait([
        api.listCenters(locale: locale),
        api.listDevices(locale: locale),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _centers = results[0] as List<NetworkCenter>;
        _devices = results[1] as List<NetworkDevice>;
        _isLoading = false;
        _isRefreshing = false;
        _error = null;
      });
    } on NetworkApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.networkLoadFailed;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await AuthScope.of(context).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.networkCentersTitle),
        actions: [
          const LanguageSwitcher(),
          TextButton(
            onPressed: _logout,
            child: Text(l10n.logoutButton),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;

    if (_isLoading && !_hasData && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && !_hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
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

    return RefreshIndicator(
      onRefresh: () => _load(refreshing: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          if (_error != null && _hasData)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Text(
            l10n.networkCentersSectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (_centers.isEmpty)
            _EmptySectionMessage(
              title: l10n.networkCentersEmptyTitle,
              description: l10n.networkCentersEmptyDescription,
            )
          else
            ..._centers.map(
              (center) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NetworkCenterTile(center: center),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            l10n.networkDevicesTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.networkDevicesHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () => context.push('/kiosk/enroll'),
              child: Text(l10n.networkAddDevice),
            ),
          ),
          const SizedBox(height: 12),
          if (_devices.isEmpty)
            _EmptySectionMessage(title: l10n.networkDevicesEmpty)
          else
            ..._devices.map(
              (device) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NetworkDeviceTile(device: device),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptySectionMessage extends StatelessWidget {
  const _EmptySectionMessage({
    required this.title,
    this.description,
  });

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
