import 'dart:math';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';

String _safetyUuid() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class AccountSafetyScreen extends StatefulWidget {
  const AccountSafetyScreen({super.key});

  @override
  State<AccountSafetyScreen> createState() => _AccountSafetyScreenState();
}

class _AccountSafetyScreenState extends State<AccountSafetyScreen> {
  final _description = TextEditingController();
  final _idempotencyKey = _safetyUuid();
  String _category = 'adult_conduct';
  String _priority = 'normal';
  bool _submitting = false;
  bool _loaded = false;
  String? _error;
  SafetyCaseReceipt? _receipt;
  List<SafetyCaseSummary> _cases = const [];

  bool get _ru => LocaleScope.of(context).localeCode == 'ru';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    AuthScope.of(context)
        .parentApi
        .listSafetyCases(locale: LocaleScope.of(context).localeCode)
        .then((value) {
      if (mounted) setState(() => _cases = value);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final receipt = await AuthScope.of(context).parentApi.createSafetyCase(
        category: _category,
        description: _description.text.trim(),
        idempotencyKey: _idempotencyKey,
        locale: LocaleScope.of(context).localeCode,
        priority: _priority,
      );
      if (mounted) setState(() => _receipt = receipt);
    } on ParentApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ru = _ru;
    return ParentScaffold(
      title: ru ? 'Безопасность ребёнка' : 'Child safety',
      body: AccountDeskFormShell(
        child: _receipt != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(ru ? 'Обращение принято' : 'Concern received',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SelectableText(_receipt!.caseNumber),
                  const SizedBox(height: 8),
                  Text(ru ? 'Статус: получено' : 'Status: received'),
                  const SizedBox(height: 12),
                  Text(ru
                      ? 'При непосредственной опасности звоните 112.'
                      : 'For immediate danger, call emergency services.'),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(ru
                      ? 'Предполагаемый нарушитель не получит автоматическое уведомление.'
                      : 'The alleged person is not notified automatically.'),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: InputDecoration(labelText: ru ? 'Что произошло' : 'What happened'),
                    items: [
                      DropdownMenuItem(value: 'adult_conduct', child: Text(ru ? 'Поведение взрослого' : 'Adult conduct')),
                      DropdownMenuItem(value: 'family_risk', child: Text(ru ? 'Опасность в семье' : 'Family concern')),
                      DropdownMenuItem(value: 'harmful_content', child: Text(ru ? 'Опасный материал' : 'Harmful content')),
                      DropdownMenuItem(value: 'exposed_access', child: Text(ru ? 'Раскрыт QR или доступ' : 'Exposed QR or access')),
                      DropdownMenuItem(value: 'lost_device', child: Text(ru ? 'Потеряно устройство' : 'Lost device')),
                      DropdownMenuItem(value: 'dangerous_link', child: Text(ru ? 'Опасная ссылка' : 'Dangerous link')),
                      DropdownMenuItem(value: 'other', child: Text(ru ? 'Другое' : 'Other')),
                    ],
                    onChanged: (value) => setState(() => _category = value ?? 'other'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: InputDecoration(labelText: ru ? 'Срочность' : 'Urgency'),
                    items: [
                      DropdownMenuItem(value: 'urgent', child: Text(ru ? 'Опасность сейчас' : 'Immediate danger')),
                      DropdownMenuItem(value: 'high', child: Text(ru ? 'Высокий риск' : 'High risk')),
                      DropdownMenuItem(value: 'normal', child: Text(ru ? 'Обычное обращение' : 'Standard')),
                      DropdownMenuItem(value: 'low', child: Text(ru ? 'Низкая срочность' : 'Low')),
                    ],
                    onChanged: (value) => setState(() => _priority = value ?? 'normal'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _description,
                    decoration: InputDecoration(
                      alignLabelWithHint: true,
                      labelText: ru ? 'Кратко опишите ситуацию' : 'Briefly describe the concern',
                    ),
                    maxLength: 2000,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ru
                        ? 'Не отправляйте пароль, OTP или незаконное изображение. При угрозе жизни звоните 112.'
                        : 'Do not send passwords, OTP codes, or illegal images. Call emergency services for immediate danger.',
                  ),
                  const SizedBox(height: 20),
                  AccountPrimaryButton(
                    isLoading: _submitting,
                    label: ru ? 'Отправить обращение' : 'Send concern',
                    onPressed: _submitting ? null : _submit,
                  ),
                  if (_cases.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(ru ? 'Мои обращения' : 'My concerns',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final item in _cases)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.caseNumber),
                        trailing: Text(item.status),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}
