import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authSession,
    this.redirectPath,
  });

  final AuthSession authSession;
  final String? redirectPath;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final homePath = await widget.authSession.login(
        login: _loginController.text.trim(),
        password: _passwordController.text,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      final redirect = widget.redirectPath?.trim();
      if (redirect != null && redirect.isNotEmpty) {
        context.go(redirect);
        return;
      }
      if (widget.authSession.familySetupComplete == false) {
        context.go('/parent/family-setup');
        return;
      }
      context.go(mapHomePathToMobile(homePath));
    } on AuthApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = context.l10n.loginFailed);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthScaffold(
      title: l10n.loginTitle,
      centerContent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) AuthErrorBanner(message: _error!),
          AuthTextField(
            controller: _loginController,
            label: l10n.loginFieldLabel,
            labelAsPlaceholder: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _passwordController,
            label: l10n.passwordLabel,
            labelAsPlaceholder: true,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
          ),
          const SizedBox(height: 12),
          AuthTextLink(
            label: l10n.forgotPassword,
            align: Alignment.centerRight,
            onPressed: () => context.push('/password-reset'),
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: l10n.signInButton,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          ),
          const SizedBox(height: 28),
          AuthTextLink(
            label: l10n.noAccountRegister,
            align: Alignment.center,
            onPressed: () => context.push('/register'),
          ),
        ],
      ),
    );
  }
}
