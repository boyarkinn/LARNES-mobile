import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/core/api/admin_trainers_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/features/admin/screens/trainer_play_labels.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_text_field.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';

class TrainerPlayPanel extends StatefulWidget {
  const TrainerPlayPanel({super.key, required this.trainerKey});

  final String trainerKey;

  @override
  TrainerPlayPanelState createState() => TrainerPlayPanelState();
}

class TrainerPlayPanelState extends State<TrainerPlayPanel> {
  bool _isLoading = true;
  String? _error;
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
        reload();
      }
    });
  }

  Future<void> reload({bool silent = false}) => _load(silent: silent);

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
      final config = await AuthScope.of(context).adminTrainersApi.fetchPlayConfig(
            trainerKey: widget.trainerKey,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _config = config;
        _values = config.initialValues();
        _isLoading = false;
        _error = null;
      });
    } on AdminTrainersApiException catch (error) {
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
        _error = context.l10n.adminTrainerPlayLoadFailed;
        _isLoading = false;
      });
    }
  }

  void _setValue(String key, String value) {
    setState(() {
      _values = {..._values, key: value};
    });
  }

  void _launch() {
    final config = _config;
    if (config == null) {
      return;
    }

    final payload = buildPlayParamsPayload(config, _values);
    context.push(
      '/admin/trainers/${widget.trainerKey}/play',
      extra: AdminTrainerPlayLaunch(
        trainerKey: widget.trainerKey,
        title: config.title,
        params: payload,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: _buildBodyChildren(l10n),
      ),
    );
  }

  List<Widget> _buildBodyChildren(AppLocalizations l10n) {
    if (!_hasMobilePlay) {
      return [
        const SizedBox(height: 48),
        Text(
          l10n.adminTrainerPlayWebOnlyTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AdminColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.adminTrainerPlayWebOnlyMessage,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: AdminColors.inkMuted),
        ),
      ];
    }

    if (_isLoading && _config == null) {
      return [
        const SizedBox(height: 120),
        const Center(child: CircularProgressIndicator(color: AdminColors.accent)),
      ];
    }

    if (_error != null && _config == null) {
      return [
        const SizedBox(height: 48),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AdminColors.inkMuted),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminColors.accent),
            onPressed: () => _load(),
            child: Text(l10n.continueButton),
          ),
        ),
      ];
    }

    final config = _config;
    if (config == null) {
      return [const SizedBox(height: 1)];
    }

    final fieldRevision = config.trainerKey == 'flashcard-digit-match'
        ? (_values['pairCount'] ?? '2')
        : 'static';

    return [
      Text(
        l10n.adminTrainerPlayMobileHint,
        style: GoogleFonts.inter(fontSize: 13, color: AdminColors.inkMuted),
      ),
      const SizedBox(height: 12),
      if (config.isInteractive)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            l10n.adminTrainerPlayInteractiveHint,
            style: GoogleFonts.inter(fontSize: 13, color: AdminColors.inkMuted),
          ),
        ),
      for (final field in config.fields)
        if (trainerPlayFieldVisible(config, field, _values)) ...[
          _FieldEditor(
            key: ValueKey('${field.key}-$fieldRevision'),
            field: field,
            l10n: l10n,
            value: _values[field.key] ?? '',
            onChanged: (value) => _setValue(field.key, value),
          ),
          const SizedBox(height: 12),
        ],
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AdminColors.accent,
          minimumSize: const Size.fromHeight(48),
        ),
        onPressed: _launch,
        child: Text(l10n.adminTrainerPlayLaunch),
      ),
    ];
  }
}

class _FieldEditor extends StatefulWidget {
  const _FieldEditor({
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
  State<_FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<_FieldEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_FieldEditor oldWidget) {
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
        return DropdownButtonFormField<String>(
          value: widget.value.isEmpty ? null : widget.value,
          decoration: AdminTextField.inputDecoration().copyWith(labelText: label),
          items: [
            for (final option in widget.field.options)
              DropdownMenuItem(
                value: option.value,
                child: Text(trainerPlayOptionLabel(widget.l10n, option)),
              ),
          ],
          onChanged: (next) {
            if (next != null) {
              widget.onChanged(next);
            }
          },
        );
      case TrainerPlayFieldType.text:
        return TextFormField(
          controller: _controller,
          decoration: AdminTextField.inputDecoration().copyWith(labelText: label),
          maxLength: widget.field.maxLength,
          onChanged: widget.onChanged,
        );
      case TrainerPlayFieldType.number:
        return TextFormField(
          controller: _controller,
          decoration: AdminTextField.inputDecoration().copyWith(labelText: label),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))],
          onChanged: widget.onChanged,
        );
    }
  }
}
