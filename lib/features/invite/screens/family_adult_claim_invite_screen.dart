import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_invite_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_invite_widgets.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/core/api/family_adult_claim_api.dart';
import 'package:larnes_mobile/core/api/places_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/formatting/date_of_birth_input.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/widgets/place_autocomplete_field.dart';
import 'package:larnes_mobile/features/auth/widgets/date_of_birth_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/otp_input.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

enum _ClaimStep { intro, otp, parent }

String _uuid() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class FamilyAdultClaimInviteScreen extends StatefulWidget {
  const FamilyAdultClaimInviteScreen({super.key, required this.token});

  final String token;

  @override
  State<FamilyAdultClaimInviteScreen> createState() => _FamilyAdultClaimInviteScreenState();
}

class _FamilyAdultClaimInviteScreenState extends State<FamilyAdultClaimInviteScreen> {
  bool _isLoading = true;
  bool _isPending = false;
  String? _error;
  FamilyAdultClaimInvitation? _invitation;
  _ClaimStep _step = _ClaimStep.intro;
  String? _claimVerificationToken;
  int _secondsLeft = 0;
  Timer? _cooldown;

  final _otpController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordRepeatController = TextEditingController();
  PlaceCitySelection? _citySelection;
  bool _termsAccepted = false;
  final _idempotencyKey = _uuid();

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
    _cooldown?.cancel();
    _otpController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _patronymicController.dispose();
    _dateOfBirthController.dispose();
    _passwordController.dispose();
    _passwordRepeatController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldown?.cancel();
    setState(() => _secondsLeft = 60);
    _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() => _secondsLeft = 0);
        }
        return;
      }
      if (mounted) {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _load() async {
    if (widget.token.isEmpty) {
      setState(() {
        _error = context.l10n.inviteInvalid;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final invitation = await AuthScope.of(context).familyAdultClaimApi.fetchInvite(
            token: widget.token,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      _firstNameController.text = invitation.parent.firstName;
      _lastNameController.text = invitation.parent.lastName ?? '';
      _patronymicController.text = invitation.parent.patronymic ?? '';
      _dateOfBirthController.text = invitation.parent.dateOfBirth ?? '';
      setState(() {
        _invitation = invitation;
        _isLoading = false;
      });
    } on FamilyAdultClaimApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.requestFailed;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _goAfterSuccess(String next) async {
    final auth = AuthScope.of(context);
    final locale = LocaleScope.of(context).localeCode;
    await auth.refreshFamilySetup(locale: locale);
    auth.notifyParentDataChanged();
    if (!mounted) {
      return;
    }
    if (next == 'confirm_children') {
      context.go('/parent/family/confirm-children');
      return;
    }
    context.go('/parent');
  }

  Future<void> _sendOtp({bool resend = false}) async {
    setState(() {
      _isPending = true;
      _error = null;
    });
    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).familyAdultClaimApi.sendOtp(
            token: widget.token,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      _startCooldown();
      setState(() {
        _step = _ClaimStep.otp;
        _isPending = false;
      });
    } on FamilyAdultClaimApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isPending = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.requestFailed;
          _isPending = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() => _error = context.l10n.enterSixDigitCode);
      return;
    }
    setState(() {
      _isPending = true;
      _error = null;
    });
    try {
      final locale = LocaleScope.of(context).localeCode;
      final token = await AuthScope.of(context).familyAdultClaimApi.verifyOtp(
            token: widget.token,
            code: code,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _claimVerificationToken = token;
        _step = _ClaimStep.parent;
        _isPending = false;
      });
    } on FamilyAdultClaimApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isPending = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.requestFailed;
          _isPending = false;
        });
      }
    }
  }

  Future<void> _acceptLoggedIn() async {
    final claimToken = _claimVerificationToken;
    if (claimToken == null || claimToken.isEmpty) {
      setState(() => _error = context.l10n.inviteFamilyAdultClaimContactNotVerified);
      return;
    }
    setState(() {
      _isPending = true;
      _error = null;
    });
    try {
      final locale = LocaleScope.of(context).localeCode;
      final next = await AuthScope.of(context).familyAdultClaimApi.accept(
            token: widget.token,
            claimVerificationToken: claimToken,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      await _goAfterSuccess(next);
    } on FamilyAdultClaimApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isPending = false;
          if (error.verificationExpired) {
            _step = _ClaimStep.otp;
            _claimVerificationToken = null;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.requestFailed;
          _isPending = false;
        });
      }
    }
  }

  Future<void> _completeRegister() async {
    final l10n = context.l10n;
    final claimToken = _claimVerificationToken;
    if (claimToken == null || claimToken.isEmpty) {
      setState(() => _error = l10n.inviteFamilyAdultClaimContactNotVerified);
      return;
    }
    if (_citySelection == null) {
      setState(() => _error = l10n.cityLabel);
      return;
    }
    if (!_termsAccepted) {
      setState(() => _error = l10n.registrationTermsRequired);
      return;
    }
    if (_passwordController.text != _passwordRepeatController.text) {
      setState(() => _error = l10n.passwordsDoNotMatch);
      return;
    }
    final dob = displayDateToIso(_dateOfBirthController.text.trim());
    if (dob == null) {
      setState(() => _error = l10n.invalidDateOfBirth);
      return;
    }

    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final auth = AuthScope.of(context);
      final result = await auth.familyAdultClaimApi.complete(
            token: widget.token,
            claimVerificationToken: claimToken,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            patronymic: _patronymicController.text.trim(),
            dateOfBirth: dob,
            password: _passwordController.text,
            confirmPassword: _passwordRepeatController.text,
            placeMapboxId: _citySelection!.mapboxId,
            termsAccepted: _termsAccepted,
            termsVersionId: _invitation!.termsVersionId,
            idempotencyKey: _idempotencyKey,
            locale: locale,
          );
      auth.applyUser(result.user);
      if (!mounted) {
        return;
      }
      await _goAfterSuccess(result.next);
    } on FamilyAdultClaimApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isPending = false;
          if (error.verificationExpired) {
            _step = _ClaimStep.otp;
            _claimVerificationToken = null;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.requestFailed;
          _isPending = false;
        });
      }
    }
  }

  Future<void> _decline() async {
    setState(() {
      _isPending = true;
      _error = null;
    });
    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).familyAdultClaimApi.decline(
            token: widget.token,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      context.go('/login');
    } on FamilyAdultClaimApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isPending = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.requestFailed;
          _isPending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final invitation = _invitation;

    if (_isLoading) {
      return AuthInviteShell(
        title: l10n.inviteFamilyAdultClaimTitleShort,
        claim: true,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && invitation == null) {
      return AuthInviteShell(
        title: l10n.inviteInvalidTitle,
        claim: true,
        child: AuthErrorBanner(message: _error!),
      );
    }

    if (invitation!.isWrongAccount) {
      return AuthInviteShell(
        title: l10n.inviteFamilyAdultClaimWrongAccountTitle,
        subtitle: l10n.inviteFamilyAdultClaimWrongAccountSubtitle,
        claim: true,
        child: AuthPrimaryButton(
          label: l10n.logoutButton,
          useWebAuthStyle: true,
          onPressed: () async {
            await AuthScope.of(context).logout();
            if (context.mounted) {
              context.go(
                '/invite/family-adult-claim?token=${Uri.encodeComponent(widget.token)}',
              );
            }
          },
        ),
      );
    }

    final title = switch (_step) {
      _ClaimStep.intro => l10n.inviteFamilyAdultClaimTitle(invitation.networkName),
      _ClaimStep.otp => l10n.inviteFamilyAdultClaimOtpTitle,
      _ClaimStep.parent => invitation.isLoggedIn
          ? l10n.inviteFamilyAdultClaimLoggedInTitle
          : l10n.inviteFamilyAdultClaimProfileTitle,
    };

    return AuthInviteShell(
      title: title,
      claim: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_step == _ClaimStep.intro) ...[
            Text(
              l10n.inviteFamilyAdultClaimSubtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: AuthColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            AuthInviteContextCard(
              label: l10n.inviteFamilyAdultClaimContactLabel,
              value: invitation.contactMasked,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              AuthErrorBanner(message: _error!),
            ],
            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: l10n.inviteFamilyAdultClaimAccept,
              isLoading: _isPending,
              useWebAuthStyle: true,
              onPressed: () => _sendOtp(),
            ),
            const SizedBox(height: 10),
            AuthSecondaryButton(
              label: l10n.inviteFamilyAdultClaimDecline,
              isLoading: _isPending,
              onPressed: _isPending ? null : _decline,
            ),
          ],
          if (_step == _ClaimStep.otp) ...[
            Text(
              '${l10n.inviteFamilyAdultClaimOtpSentTo} ${invitation.contactMasked}',
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: AuthColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            OtpInput(controller: _otpController, useWebAuthStyle: true),
            if (_error != null) ...[
              const SizedBox(height: 12),
              AuthErrorBanner(message: _error!),
            ],
            const SizedBox(height: 16),
            AuthPrimaryButton(
              label: l10n.inviteFamilyAdultClaimOtpSubmit,
              isLoading: _isPending,
              useWebAuthStyle: true,
              onPressed: _verifyOtp,
            ),
            const SizedBox(height: 8),
            AuthTextLink(
              label: _secondsLeft > 0
                  ? l10n.inviteFamilyAdultClaimOtpResendIn(_secondsLeft)
                  : l10n.inviteFamilyAdultClaimOtpResend,
              useWebAuthStyle: true,
              onPressed: (_isPending || _secondsLeft > 0) ? null : () => _sendOtp(resend: true),
            ),
          ],
          if (_step == _ClaimStep.parent && invitation.isLoggedIn) ...[
            Text(
              l10n.inviteFamilyAdultClaimLoggedInSubtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: AuthColors.muted,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              AuthErrorBanner(message: _error!),
            ],
            const SizedBox(height: 16),
            AuthPrimaryButton(
              label: l10n.inviteFamilyAdultClaimLoggedInSubmit,
              isLoading: _isPending,
              useWebAuthStyle: true,
              onPressed: _acceptLoggedIn,
            ),
          ],
          if (_step == _ClaimStep.parent && !invitation.isLoggedIn) ...[
            Text(
              l10n.inviteFamilyAdultClaimProfileHint,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: AuthColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            AuthInput(
              controller: _lastNameController,
              label: l10n.lastNameLabel,
            ),
            const SizedBox(height: AuthMetrics.formGap),
            AuthInput(
              controller: _firstNameController,
              label: l10n.firstNameLabel,
            ),
            const SizedBox(height: AuthMetrics.formGap),
            AuthInput(
              controller: _patronymicController,
              label: l10n.patronymicLabel,
            ),
            const SizedBox(height: AuthMetrics.formGap),
            DateOfBirthTextField(
              controller: _dateOfBirthController,
              label: l10n.dateOfBirthLabel,
            ),
            const SizedBox(height: AuthMetrics.formGap),
            PlaceAutocompleteField(
              placesApi: AuthScope.of(context).placesApi,
              locale: LocaleScope.of(context).localeCode,
              label: l10n.cityLabel,
              initialDisplayLabel: invitation.parent.city ?? '',
              initialMapboxId: invitation.parent.placeId,
              onChanged: (selection) => setState(() => _citySelection = selection),
            ),
            const SizedBox(height: AuthMetrics.formGap),
            AuthInput(
              controller: _passwordController,
              label: l10n.passwordLabel,
              obscureText: true,
              enablePasswordToggle: true,
            ),
            const SizedBox(height: AuthMetrics.formGap),
            AuthInput(
              controller: _passwordRepeatController,
              label: l10n.repeatPasswordLabel,
              obscureText: true,
              enablePasswordToggle: true,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _termsAccepted,
              onChanged: (value) => setState(() => _termsAccepted = value ?? false),
              title: Text(l10n.registrationTermsParent),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_error != null) AuthErrorBanner(message: _error!),
            const SizedBox(height: AuthMetrics.formGap),
            AuthPrimaryButton(
              label: l10n.inviteFamilyAdultClaimProfileSubmit,
              isLoading: _isPending,
              useWebAuthStyle: true,
              onPressed: _completeRegister,
            ),
          ],
        ],
      ),
    );
  }
}
