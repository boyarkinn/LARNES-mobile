import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/api/register_api.dart';
import 'package:larnes_mobile/core/config/mobile_config.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/turnstile_widget.dart';

class RegisterContactScreen extends StatefulWidget {
  const RegisterContactScreen({super.key, required this.accountType});

  final RegisterAccountType accountType;

  @override
  State<RegisterContactScreen> createState() => _RegisterContactScreenState();
}

class _RegisterContactScreenState extends State<RegisterContactScreen> {
  RegisterContactChannel _channel = RegisterContactChannel.sms;
  final _contactController = TextEditingController();
  MobileConfig? _config;
  String? _turnstileToken;
  int _turnstileResetKey = 0;
  bool _isLoadingConfig = true;
  bool _isSubmitting = false;
  String? _error;

  bool _configLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_configLoaded) {
      _configLoaded = true;
      _loadConfig();
    }
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await AuthScope.of(context).registerApi.fetchConfig();
      if (mounted) {
        setState(() {
          _config = config;
          _isLoadingConfig = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _config = MobileConfig.fallback;
          _isLoadingConfig = false;
        });
      }
    }
  }

  Future<void> _continue() async {
    final contact = _contactController.text.trim();
    if (contact.isEmpty) {
      setState(() => _error = 'Введите контакт');
      return;
    }

    final config = _config ?? MobileConfig.fallback;
    if (config.turnstileRequired && (_turnstileToken == null || _turnstileToken!.isEmpty)) {
      setState(() => _error = 'Подтвердите, что вы не робот');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final normalized = await AuthScope.of(context).registerApi.sendOtp(
        channel: _channel,
        contact: contact,
        turnstileToken: _turnstileToken,
      );
      if (!mounted) {
        return;
      }

      final flow = RegisterFlowData(
        accountType: widget.accountType,
        contact: normalized,
        channel: _channel,
      );

      context.push(
        '/register/${widget.accountType.routeSlug}/otp',
        extra: flow,
      );
    } on RegisterApiException catch (error) {
      setState(() => _error = error.message);
      _resetTurnstile();
    } catch (error) {
      setState(() => _error = error.toString());
      _resetTurnstile();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetTurnstile() {
    final config = _config ?? MobileConfig.fallback;
    if (!config.turnstileRequired) {
      return;
    }
    setState(() {
      _turnstileToken = null;
      _turnstileResetKey += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = _channel == RegisterContactChannel.sms;
    final config = _config ?? MobileConfig.fallback;

    return AuthScaffold(
      showBackButton: true,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: widget.accountType.label,
            subtitle: 'Шаг 1 из 3 — подтверждение контакта',
          ),
          if (_error != null) AuthErrorBanner(message: _error!),
          SegmentedButton<RegisterContactChannel>(
            segments: const [
              ButtonSegment(
                value: RegisterContactChannel.sms,
                label: Text('Телефон'),
              ),
              ButtonSegment(
                value: RegisterContactChannel.email,
                label: Text('Почта'),
              ),
            ],
            selected: {_channel},
            onSelectionChanged: (value) {
              setState(() {
                _channel = value.first;
                _turnstileToken = null;
                _turnstileResetKey += 1;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _contactController,
            label: isPhone ? 'Телефон' : 'Email',
            keyboardType:
                isPhone ? TextInputType.phone : TextInputType.emailAddress,
          ),
          if (_isLoadingConfig)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            )
          else if (config.turnstileRequired && config.turnstilePageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            TurnstileWidget(
              key: ValueKey('turnstile-${widget.accountType.routeSlug}-$_channel'),
              pageUrl: config.turnstilePageUrl,
              resetKey: _turnstileResetKey,
              onTokenChanged: (token) => setState(() => _turnstileToken = token),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSubmitting || _isLoadingConfig ? null : _continue,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Получить код'),
          ),
        ],
      ),
    );
  }
}
