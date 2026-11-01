import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/kiosk/kiosk_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authSession, this.redirectPath});

  final AuthSession authSession;
  final String? redirectPath;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _rememberMe = false;
  String? _error;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final outcome = await widget.authSession.login(
        login: _loginController.text.trim(),
        password: _passwordController.text,
        locale: locale,
        rememberMe: _rememberMe,
      );
      if (!mounted) {
        return;
      }

      if (outcome is DeviceEnrollmentLoginOutcome) {
        TextInput.finishAutofillContext(shouldSave: false);
        if (widget.authSession.isAuthenticated) {
          await widget.authSession.logout();
        }
        if (!mounted) return;
        await KioskScope.of(context).persistDeviceToken(outcome.deviceToken);
        if (!mounted) {
          return;
        }
        context.go('/kiosk');
        return;
      }

      final userOutcome = outcome as UserLoginOutcome;
      TextInput.finishAutofillContext(shouldSave: true);
      final saved = userOutcome.user.interfaceLocale;
      if (saved != null && (saved == 'en' || saved == 'ru')) {
        await LocaleScope.read(context).applyAccountLocale(saved);
      }
      if (!mounted) return;
      final redirect = widget.redirectPath?.trim();
      context.go(
        resolvePostAuthDestination(
          accountType: widget.authSession.user?.accountType,
          homePath: userOutcome.homePath,
          familySetupComplete: widget.authSession.familySetupComplete,
          redirectPath: redirect,
        ),
      );
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.loginFailed);
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
      variant: AuthScaffoldVariant.web,
      centerContent: true,
      child: AutofillGroup(
        onDisposeAction: AutofillContextAction.cancel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthCompactKicker(text: l10n.loginEyebrow),
            if (_error != null) AuthErrorBanner(message: _error!),
            AuthInput(
              controller: _loginController,
              label: l10n.loginFieldLabel,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
            ),
            const SizedBox(height: AuthMetrics.formGap),
            AuthInput(
              controller: _passwordController,
              label: l10n.passwordLabel,
              obscureText: true,
              enablePasswordToggle: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _isSubmitting ? null : _submit(),
            ),
            // The touch row adds 13px around its 18px contents on each side.
            const SizedBox(height: AuthMetrics.formGap - 13),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                IntrinsicWidth(
                  child: AuthTextLink(
                    label: l10n.forgotPassword,
                    align: Alignment.centerLeft,
                    useWebAuthStyle: true,
                    onPressed: () => context.push('/password-reset'),
                  ),
                ),
                MergeSemantics(
                  child: InkWell(
                    onTap: _isSubmitting
                        ? null
                        : () => setState(() => _rememberMe = !_rememberMe),
                    borderRadius: BorderRadius.circular(AuthRadii.input),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 4),
                          SizedBox.square(
                            dimension: 18,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: AuthColors.cobaltDeep,
                              checkColor: Colors.white,
                              side: const BorderSide(
                                color: AuthColors.cobaltDeep,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: _isSubmitting
                                  ? null
                                  : (value) => setState(
                                      () => _rememberMe = value ?? false,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.rememberMe,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isSubmitting
                                  ? AuthColors.muted
                                  : AuthColors.cobaltDeep,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AuthMetrics.formGap - 13),
            AuthPrimaryButton(
              label: _isSubmitting ? l10n.loginPending : l10n.signInButton,
              isLoading: _isSubmitting,
              useWebAuthStyle: true,
              onPressed: _isSubmitting ? null : _submit,
            ),
            AuthFormFoot(
              leadText: l10n.loginNoAccount,
              linkLabel: l10n.loginRegisterLink,
              onLinkPressed: () => context.push('/register'),
            ),
          ],
        ),
      ),
    );
  }
}
