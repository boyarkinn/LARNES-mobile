import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/core/api/register_school_offers_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/auth_flow_labels.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_web_flow_shell.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class RegisterSchoolOffersScreen extends StatefulWidget {
  const RegisterSchoolOffersScreen({super.key, required this.flow});

  final RegisterFlowData flow;

  @override
  State<RegisterSchoolOffersScreen> createState() => _RegisterSchoolOffersScreenState();
}

class _RegisterSchoolOffersScreenState extends State<RegisterSchoolOffersScreen> {
  bool _isLoading = true;
  bool _isPending = false;
  String? _error;
  List<PendingSchoolOffer> _offers = const [];
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final locale = LocaleScope.read(context).localeCode;
      final offers = await AuthScope.of(context).registerSchoolOffersApi.listOffers(
            channel: widget.flow.channel,
            contact: widget.flow.contact,
            verificationToken: widget.flow.verificationToken,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      if (offers.isEmpty) {
        context.pushReplacement(
          '/register/${widget.flow.accountType.routeSlug}/profile',
          extra: widget.flow,
        );
        return;
      }
      setState(() {
        _offers = offers;
        _selected
          ..clear()
          ..addAll(offers.map((o) => o.childId));
        _isLoading = false;
      });
    } on RegisterSchoolOffersApiException catch (error) {
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

  Future<void> _skip() async {
    setState(() {
      _isPending = true;
      _error = null;
    });
    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).registerSchoolOffersApi.skip(
            channel: widget.flow.channel,
            contact: widget.flow.contact,
            verificationToken: widget.flow.verificationToken,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      context.push(
        '/register/${widget.flow.accountType.routeSlug}/profile',
        extra: widget.flow,
      );
    } on RegisterSchoolOffersApiException catch (error) {
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

  void _continueWithOffers() {
    if (_selected.isEmpty) {
      setState(() => _error = context.l10n.registerSchoolOffersSelectOne);
      return;
    }
    final primary = _selected.first;
    context.push(
      '/register/${widget.flow.accountType.routeSlug}/profile',
      extra: widget.flow.copyWith(
        selectedSchoolOfferChildIds: _selected.toList(),
        primarySchoolOfferChildId: primary,
        schoolOffers: _offers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthWebFlowShell(
      showBackButton: true,
      onBack: () => context.pop(),
      stepLabels: registerWizardStepLabels(context),
      currentStep: 2,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.registerSchoolOffersLead,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: AuthColors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                for (final offer in _offers)
                  CheckboxListTile(
                    value: _selected.contains(offer.childId),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(offer.childId);
                        } else {
                          _selected.remove(offer.childId);
                        }
                      });
                    },
                    title: Text(
                      [
                        offer.networkDisplayName,
                        offer.childFirstName,
                      ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AuthColors.ink,
                      ),
                    ),
                    subtitle: Text(
                      offer.parentFirstName,
                      style: GoogleFonts.inter(fontSize: 13, color: AuthColors.muted),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                if (_error != null) AuthErrorBanner(message: _error!),
                AuthPrimaryButton(
                  label: l10n.registerSchoolOffersContinue,
                  isLoading: _isPending,
                  useWebAuthStyle: true,
                  onPressed: _continueWithOffers,
                ),
                const SizedBox(height: 8),
                AuthSecondaryButton(
                  label: l10n.registerSchoolOffersSkip,
                  isLoading: _isPending,
                  onPressed: _isPending ? null : _skip,
                ),
              ],
            ),
    );
  }
}
