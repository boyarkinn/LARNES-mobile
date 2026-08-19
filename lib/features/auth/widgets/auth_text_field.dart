import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';
import 'package:larnes_mobile/features/parent/widgets/account/desk_text_field.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Web auth input — `auth.css` `.auth-input` (+ password toggle).
class AuthInput extends StatefulWidget {
  const AuthInput({
    super.key,
    required this.controller,
    required this.label,
    this.labelAsPlaceholder = true,
    this.obscureText = false,
    this.enablePasswordToggle = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.errorText,
    this.onSubmitted,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final bool labelAsPlaceholder;
  final bool obscureText;
  final bool enablePasswordToggle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;

  @override
  State<AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<AuthInput> {
  bool _passwordVisible = false;
  bool _capsLock = false;

  bool get _isPasswordField => widget.obscureText || widget.enablePasswordToggle;

  bool get _hideText => _isPasswordField && !_passwordVisible;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Focus(
          onKeyEvent: _isPasswordField
              ? (node, event) {
                  if (event is KeyDownEvent || event is KeyUpEvent) {
                    final caps = HardwareKeyboard.instance.logicalKeysPressed
                        .contains(LogicalKeyboardKey.capsLock);
                    if (_capsLock != caps) {
                      setState(() => _capsLock = caps);
                    }
                  }
                  return KeyEventResult.ignored;
                }
              : null,
          child: Semantics(
            textField: true,
            label: widget.label,
            child: TextField(
              controller: widget.controller,
              readOnly: widget.readOnly,
              obscureText: _hideText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              autofillHints: widget.autofillHints,
              onSubmitted: widget.onSubmitted,
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AuthColors.ink,
              ),
              decoration: InputDecoration(
                hintText: widget.labelAsPlaceholder ? widget.label : null,
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: AuthColors.placeholder,
                ),
                filled: true,
                fillColor: hasError ? AuthColors.dangerSoft : AuthColors.surfaceStrong,
                contentPadding: EdgeInsets.fromLTRB(
                  14,
                  14,
                  _isPasswordField ? 52 : 14,
                  14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AuthRadii.input),
                  borderSide: BorderSide(
                    color: hasError
                        ? AuthColors.danger
                        : const Color.fromRGBO(26, 29, 46, 0.18),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AuthRadii.input),
                  borderSide: const BorderSide(color: AuthColors.cobalt, width: 1),
                ),
                suffixIcon: _isPasswordField
                    ? Semantics(
                        button: true,
                        label: _passwordVisible ? l10n.passwordHide : l10n.passwordShow,
                        child: IconButton(
                          onPressed: () {
                            setState(() => _passwordVisible = !_passwordVisible);
                          },
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AuthColors.muted,
                            size: 22,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
        if (_capsLock && _isPasswordField)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.passwordCapsLock,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.4,
                color: AuthColors.capsHint,
              ),
            ),
          ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.errorText!,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.4,
                color: AuthColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

/// Morning Desk field — legacy non-auth flows only.
typedef AuthTextField = DeskTextField;

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AuthMetrics.formGap),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AuthColors.dangerSoft,
        borderRadius: BorderRadius.circular(AuthRadii.input),
        border: Border.all(color: const Color.fromRGBO(180, 35, 24, 0.18)),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AuthColors.danger,
          height: 1.45,
        ),
      ),
    );
  }
}

class AuthSuccessBanner extends StatelessWidget {
  const AuthSuccessBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECF9F3),
        borderRadius: BorderRadius.circular(AuthRadii.input),
        border: Border.all(color: const Color.fromRGBO(20, 125, 82, 0.18)),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AuthColors.success,
          height: 1.45,
        ),
      ),
    );
  }
}
