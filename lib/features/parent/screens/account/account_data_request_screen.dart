import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';

class AccountDataRequestScreen extends StatefulWidget {
  const AccountDataRequestScreen({super.key});

  @override
  State<AccountDataRequestScreen> createState() => _AccountDataRequestScreenState();
}

class _AccountDataRequestScreenState extends State<AccountDataRequestScreen> {
  final _description = TextEditingController();
  final _email = TextEditingController();
  final _name = TextEditingController();
  String _requestType = 'access';
  String _subjectType = 'user';
  bool _submitting = false;
  String? _error;
  DsarReceipt? _receipt;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final user = AuthScope.of(context).user;
    _name.text = user?.fullName ?? '';
    _email.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _description.dispose();
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 2 ||
        !_email.text.contains('@') ||
        _description.text.trim().length < 10) {
      setState(() => _error = _ru ? 'Заполните все поля.' : 'Complete all fields.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final receipt = await AuthScope.of(context).parentApi.createDataRequest(
        description: _description.text.trim(),
        locale: LocaleScope.of(context).localeCode,
        requesterEmail: _email.text.trim(),
        requesterName: _name.text.trim(),
        requestType: _requestType,
        subjectType: _subjectType,
      );
      if (mounted) setState(() => _receipt = receipt);
    } on ParentApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool get _ru => LocaleScope.of(context).localeCode == 'ru';

  @override
  Widget build(BuildContext context) {
    final ru = _ru;
    return ParentScaffold(
      title: ru ? 'Запрос о данных' : 'Data request',
      body: AccountDeskFormShell(
        child: _receipt != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ru ? 'Запрос принят' : 'Request received',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(_receipt!.requestNumber),
                  const SizedBox(height: 8),
                  Text(
                    '${ru ? 'Срок ответа' : 'Reply due'}: '
                    '${MaterialLocalizations.of(context).formatMediumDate(_receipt!.dueAt)}',
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(labelText: ru ? 'Ваше имя' : 'Your name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _subjectType,
                    decoration: InputDecoration(labelText: ru ? 'Чьи данные' : 'Whose data'),
                    items: [
                      DropdownMenuItem(value: 'user', child: Text(ru ? 'Мои' : 'Mine')),
                      DropdownMenuItem(value: 'child', child: Text(ru ? 'Ребёнка' : 'A child')),
                      DropdownMenuItem(value: 'crm_contact', child: Text(ru ? 'В CRM школы' : 'School CRM')),
                    ],
                    onChanged: (value) => setState(() => _subjectType = value ?? 'user'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _requestType,
                    decoration: InputDecoration(labelText: ru ? 'Что требуется' : 'Requested action'),
                    items: [
                      DropdownMenuItem(value: 'access', child: Text(ru ? 'Получить копию' : 'Access copy')),
                      DropdownMenuItem(value: 'correction', child: Text(ru ? 'Исправить' : 'Correct')),
                      DropdownMenuItem(value: 'restriction', child: Text(ru ? 'Заблокировать' : 'Restrict')),
                      DropdownMenuItem(value: 'cessation', child: Text(ru ? 'Прекратить обработку' : 'Stop processing')),
                      DropdownMenuItem(value: 'erasure', child: Text(ru ? 'Уничтожить' : 'Erase')),
                      DropdownMenuItem(value: 'account_closure', child: Text(ru ? 'Закрыть аккаунт' : 'Close account')),
                    ],
                    onChanged: (value) => setState(() => _requestType = value ?? 'access'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _description,
                    decoration: InputDecoration(
                      labelText: ru ? 'Опишите запрос' : 'Describe your request',
                      alignLabelWithHint: true,
                    ),
                    maxLength: 4000,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 20),
                  AccountPrimaryButton(
                    isLoading: _submitting,
                    label: ru ? 'Отправить запрос' : 'Send request',
                    onPressed: _submitting ? null : _submit,
                  ),
                ],
              ),
      ),
    );
  }
}
