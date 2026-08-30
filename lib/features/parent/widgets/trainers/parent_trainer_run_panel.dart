import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/features/admin/screens/trainer_play_labels.dart';
import 'package:larnes_mobile/features/parent/trainers/parent_trainer_params_utils.dart';
import 'package:larnes_mobile/features/parent/trainers/parent_trainer_play_session.dart';
import 'package:larnes_mobile/features/parent/widgets/account/desk_text_field.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_panel_error_panel.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

class ParentTrainerRunPanel extends StatefulWidget {
  const ParentTrainerRunPanel({
    super.key,
    required this.childId,
    required this.direction,
    required this.trainerKey,
  });

  final String childId;
  final String direction;
  final String trainerKey;

  @override
  State<ParentTrainerRunPanel> createState() => _ParentTrainerRunPanelState();
}

class _ParentTrainerRunPanelState extends State<ParentTrainerRunPanel> {
  bool _isLoading = true;
  bool _isLaunching = false;
  String? _error;
  String? _clientError;
  TrainerPlayConfig? _config;
  Map<String, String> _values = {};

  bool get _hasMobilePlay => hasTrainerBuilder(widget.trainerKey);

  @override
  void initState() {
    super.initState();
    if (!_hasMobilePlay) {
      _isLoading = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!_hasMobilePlay) {
      return;
    }

    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final config = await AuthScope.of(context).parentApi.fetchTrainerPlayConfig(
        widget.trainerKey,
        locale: locale,
      );

      if (config.direction != widget.direction) {
        if (!mounted) {
          return;
        }
        setState(() {
          _error = context.l10n.parentTrainersDirectionMismatch;
          _isLoading = false;
        });
        return;
      }

      var values = config.initialValues();
      final stored = await ParentTrainerPlaySessionStore.read(widget.trainerKey);
      if (stored != null) {
        final validated = validateTrainerParams(widget.trainerKey, stored.params);
        if (validated.ok && validated.params != null) {
          values = mergeStoredParamsIntoFormValues(config, validated.params!);
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _config = config;
        _values = values;
        _isLoading = false;
        _error = null;
      });
    } on ParentApiException catch (error) {
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
        _error = context.l10n.parentTrainersPlayConfigLoadFailed;
        _isLoading = false;
      });
    }
  }

  void _setValue(String key, String value) {
    setState(() {
      _values = {..._values, key: value};
      _clientError = null;
    });
  }

  Future<void> _launch() async {
    final config = _config;
    if (config == null || _isLaunching) {
      return;
    }

    setState(() {
      _clientError = null;
      _isLaunching = true;
    });

    final payload = buildPlayParamsPayload(config, _values);
    final validated = validateTrainerParams(widget.trainerKey, payload);

    if (!validated.ok || validated.params == null) {
      setState(() {
        _clientError = validated.error ?? context.l10n.requestFailed;
        _isLaunching = false;
      });
      return;
    }

    if (config.direction != widget.direction) {
      setState(() {
        _clientError = context.l10n.parentTrainersDirectionMismatch;
        _isLaunching = false;
      });
      return;
    }

    final returnPath =
        '/parent/${widget.childId}/trainers/${widget.direction}/${widget.trainerKey}';

    await ParentTrainerPlaySessionStore.write(
      trainerKey: widget.trainerKey,
      params: validated.params!,
      returnPath: returnPath,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLaunching = false;
    });

    context.push('/parent/${widget.childId}/trainers/play/${widget.trainerKey}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!_hasMobilePlay) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.parentTrainersWebOnlyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ParentColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.parentTrainersWebOnlyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ParentColors.inkMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading && _config == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _config == null) {
      return Center(
        child: ParentPanelErrorPanel(
          message: _error!,
          onRetry: _load,
        ),
      );
    }

    final config = _config;
    if (config == null) {
      return const SizedBox.shrink();
    }

    final fieldRevision = config.trainerKey == 'flashcard-digit-match'
        ? (_values['pairCount'] ?? '2')
        : 'static';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ParentChildCardMetrics.pickerMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  config.title,
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ParentColors.ink,
                  ),
                ),
                if (config.isInteractive) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.parentTrainersPlayInteractiveHint,
                    style: const TextStyle(fontSize: 13, color: ParentColors.inkMuted),
                  ),
                ],
                const SizedBox(height: 16),
                for (final field in config.fields)
                  if (trainerPlayFieldVisible(config, field, _values)) ...[
                    _ParentTrainerFieldEditor(
                      key: ValueKey('${field.key}-$fieldRevision'),
                      field: field,
                      l10n: l10n,
                      value: _values[field.key] ?? '',
                      onChanged: (value) => _setValue(field.key, value),
                    ),
                    const SizedBox(height: 12),
                  ],
                if (_clientError != null) ...[
                  Text(
                    _clientError!,
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ParentColors.shell,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _isLaunching ? null : _launch,
                  child: Text(
                    _isLaunching ? l10n.parentTrainersLaunching : l10n.parentTrainersLaunch,
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

class _ParentTrainerFieldEditor extends StatefulWidget {
  const _ParentTrainerFieldEditor({
    super.key,
    required this.field,
    required this.l10n,
    required this.value,
    required this.onChanged,
  });

  final TrainerPlayField field;
  final AppLocalizations l10n;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_ParentTrainerFieldEditor> createState() => _ParentTrainerFieldEditorState();
}

class _ParentTrainerFieldEditorState extends State<_ParentTrainerFieldEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_ParentTrainerFieldEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = trainerPlayFieldLabel(widget.l10n, widget.field.labelKey);

    switch (widget.field.type) {
      case TrainerPlayFieldType.select:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: GoogleFonts.onest(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ParentColors.inkMuted,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              key: ValueKey('${widget.field.key}:${widget.value}'),
              initialValue: widget.value.isEmpty ? null : widget.value,
              isExpanded: true,
              decoration: DeskTextField.inputDecoration(),
              items: [
                for (final option in widget.field.options)
                  DropdownMenuItem(
                    value: option.value,
                    child: Text(
                      trainerPlayOptionLabel(widget.l10n, option),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (next) {
                if (next != null) {
                  widget.onChanged(next);
                }
              },
            ),
          ],
        );
      case TrainerPlayFieldType.text:
        return DeskTextField(
          controller: _controller,
          label: label,
          onChanged: widget.onChanged,
        );
      case TrainerPlayFieldType.number:
        return DeskTextField(
          controller: _controller,
          label: label,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
          ],
          onChanged: widget.onChanged,
        );
    }
  }
}
