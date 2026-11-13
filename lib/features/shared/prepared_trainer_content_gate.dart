import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/trainer_content_bank_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/trainers/reading/shared/content_bank.dart';

class PreparedTrainerContentGate extends StatefulWidget {
  const PreparedTrainerContentGate({
    super.key,
    required this.trainerKey,
    required this.params,
    required this.builder,
  });
  final String trainerKey;
  final Map<String, dynamic> params;
  final Widget Function(PreparedTrainerContent? content) builder;
  @override
  State<PreparedTrainerContentGate> createState() =>
      _PreparedTrainerContentGateState();
}

class _PreparedTrainerContentGateState
    extends State<PreparedTrainerContentGate> {
  PreparedTrainerContent? _content;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    if (!usesReadingContentBank(widget.trainerKey)) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final content = await AuthScope.of(context).trainerContentBankApi.prepare(
        trainerKey: widget.trainerKey,
        params: widget.params,
        uiLocale: LocaleScope.read(context).localeCode,
      );
      if (mounted)
        setState(() {
          _content = content;
          _loading = false;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: TextButton(
            onPressed: _load,
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    return widget.builder(_content);
  }
}
