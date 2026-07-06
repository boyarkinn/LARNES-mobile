import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/network_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/network/models/network_center.dart';
import 'package:larnes_mobile/features/network/models/network_classroom.dart';
import 'package:larnes_mobile/features/network/models/network_device.dart';
import 'package:larnes_mobile/features/network/utils/network_device_labels.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class KioskEnrollScreen extends StatefulWidget {
  const KioskEnrollScreen({super.key});

  @override
  State<KioskEnrollScreen> createState() => _KioskEnrollScreenState();
}

class _KioskEnrollScreenState extends State<KioskEnrollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _slotController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;
  String? _submitError;
  List<NetworkCenter> _centers = const [];
  List<NetworkClassroom> _classrooms = const [];
  String? _centerId;
  String? _classroomId;
  NetworkDeviceKind _kind = NetworkDeviceKind.phone;

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
  void dispose() {
    _slotController.dispose();
    super.dispose();
  }

  List<NetworkClassroom> get _classroomsForCenter {
    final centerId = _centerId;
    if (centerId == null) {
      return const [];
    }
    return _classrooms
        .where((classroom) => classroom.centerId == centerId)
        .toList(growable: false);
  }

  bool get _canSubmit {
    if (_isSubmitting || _centers.isEmpty || _classrooms.isEmpty) {
      return false;
    }
    final classroomId = _classroomId;
    if (classroomId == null || classroomId.isEmpty) {
      return false;
    }
    return _classroomsForCenter.any((classroom) => classroom.id == classroomId);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final api = AuthScope.of(context).networkApi;
      final results = await Future.wait([
        api.listCenters(locale: locale),
        api.listClassrooms(locale: locale),
      ]);

      if (!mounted) {
        return;
      }

      final centers = results[0] as List<NetworkCenter>;
      final classrooms = results[1] as List<NetworkClassroom>;
      final centerId = centers.isEmpty ? null : centers.first.id;
      final classroomsForCenter = centerId == null
          ? const <NetworkClassroom>[]
          : classrooms.where((item) => item.centerId == centerId);

      setState(() {
        _centers = centers;
        _classrooms = classrooms;
        _centerId = centerId;
        _classroomId = classroomsForCenter.isEmpty ? null : classroomsForCenter.first.id;
        _isLoading = false;
      });
    } on NetworkApiException catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = context.l10n.networkLoadFailed;
          _isLoading = false;
        });
      }
    }
  }

  void _onCenterChanged(String? centerId) {
    if (centerId == null) {
      return;
    }

    final classroomsForCenter =
        _classrooms.where((item) => item.centerId == centerId).toList(growable: false);

    setState(() {
      _centerId = centerId;
      _classroomId = classroomsForCenter.isEmpty ? null : classroomsForCenter.first.id;
      _submitError = null;
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final kioskRouteState = KioskScope.of(context);

    try {
      final locale = LocaleScope.read(context).localeCode;
      final result = await AuthScope.of(context).networkApi.enrollDevice(
            classroomId: _classroomId!,
            slotLabel: _slotController.text.trim(),
            kind: _kind,
            locale: locale,
          );

      await kioskRouteState.persistDeviceToken(result.deviceToken);

      if (!mounted) {
        return;
      }

      context.go('/kiosk');
    } on NetworkApiException catch (error) {
      if (mounted) {
        setState(() {
          _submitError = error.message;
          _isSubmitting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitError = context.l10n.networkLoadFailed;
          _isSubmitting = false;
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
          onPressed: () => context.go('/network'),
        ),
        title: Text(l10n.kioskEnrollTitle),
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

    if (_centers.isEmpty) {
      return _EmptyMessage(text: l10n.kioskEnrollNoCenters);
    }

    if (_classrooms.isEmpty) {
      return _EmptyMessage(text: l10n.kioskEnrollNoClassrooms);
    }

    final classroomsForCenter = _classroomsForCenter;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          l10n.kioskEnrollTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.kioskEnrollSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        if (_submitError != null) ...[
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _submitError!,
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _centerId,
                decoration: InputDecoration(
                  labelText: l10n.kioskEnrollCenter,
                  border: const OutlineInputBorder(),
                ),
                items: _centers
                    .map(
                      (center) => DropdownMenuItem(
                        value: center.id,
                        child: Text(center.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _onCenterChanged,
              ),
              const SizedBox(height: 16),
              if (classroomsForCenter.isEmpty)
                _EmptyMessage(text: l10n.kioskEnrollNoClassroomsForCenter)
              else
                DropdownButtonFormField<String>(
                  initialValue: _classroomId,
                  decoration: InputDecoration(
                    labelText: l10n.kioskEnrollClassroom,
                    border: const OutlineInputBorder(),
                  ),
                  hint: Text(l10n.kioskEnrollClassroomPlaceholder),
                  items: classroomsForCenter
                      .map(
                        (classroom) => DropdownMenuItem(
                          value: classroom.id,
                          child: Text(classroom.title),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setState(() {
                      _classroomId = value;
                      _submitError = null;
                    });
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _slotController,
                decoration: InputDecoration(
                  labelText: l10n.kioskEnrollSlot,
                  hintText: l10n.kioskEnrollSlotPlaceholder,
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.kioskEnrollSlotRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<NetworkDeviceKind>(
                initialValue: _kind,
                decoration: InputDecoration(
                  labelText: l10n.kioskEnrollKind,
                  border: const OutlineInputBorder(),
                ),
                items: NetworkDeviceKind.values
                    .map(
                      (kind) => DropdownMenuItem(
                        value: kind,
                        child: Text(networkDeviceKindLabel(kind, l10n)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _kind = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _canSubmit ? _submit : null,
                child: Text(_isSubmitting ? l10n.kioskEnrollSubmitting : l10n.kioskEnrollSubmit),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}
