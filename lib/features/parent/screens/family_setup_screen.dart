import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/family_setup_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:share_plus/share_plus.dart';

class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  bool _isLoading = true;
  bool _isPending = false;
  bool _dedupAvailable = false;
  String? _error;
  FamilySetupSnapshot? _snapshot;

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
      final snapshot = await AuthScope.of(context).familySetupApi.fetchStatus(locale: locale);
      if (!mounted) {
        return;
      }
      AuthScope.of(context).applyFamilySetup(snapshot);
      if (snapshot.isComplete) {
        context.go('/parent');
        return;
      }
      var dedupAvailable = false;
      if (snapshot.isPendingJoin && snapshot.pendingJoinToken != null) {
        final dedup = await AuthScope.of(context).familyJoinDedupApi.fetchContext(
              token: snapshot.pendingJoinToken!,
              kind: 'family-join-request',
              locale: locale,
            );
        dedupAvailable = dedup != null;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _dedupAvailable = dedupAvailable;
        _isLoading = false;
      });
    } on FamilySetupApiException catch (error) {
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

  Future<void> _answer(String answer) async {
    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final auth = AuthScope.of(context);
      final snapshot = await auth.familySetupApi.answer(answer: answer, locale: locale);
      auth.applyFamilySetup(snapshot);
      if (!mounted) {
        return;
      }
      if (snapshot.isComplete) {
        context.go('/parent');
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _isPending = false;
      });
    } on FamilySetupApiException catch (error) {
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

  Future<void> _cancelJoin() async {
    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final auth = AuthScope.of(context);
      final snapshot = await auth.familySetupApi.cancelJoin(locale: locale);
      auth.applyFamilySetup(snapshot);
      if (!mounted) {
        return;
      }
      context.go('/parent');
    } on FamilySetupApiException catch (error) {
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

  Future<void> _copyLink(String url) async {
    final l10n = context.l10n;
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.parentFamilySetupCopySuccess)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.parentFamilySetupCopyFailed)),
        );
      }
    }
  }

  Future<void> _shareLink(String url) async {
    await SharePlus.instance.share(ShareParams(text: url));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ParentScaffold(
      title: l10n.parentFamilySetupGateTitle,
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(dynamic l10n) {
    if (_isLoading && _snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _snapshot == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: ParentColors.inkMuted)),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: ParentColors.shell),
                onPressed: _load,
                child: Text(l10n.continueButton),
              ),
            ],
          ),
        ),
      );
    }

    final snapshot = _snapshot!;
    final isWaiting = snapshot.isPendingJoin;

    return AccountDeskShell(
      children: [
        AccountDeskCard(
          child: Padding(
            padding: AccountDeskMetrics.formPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isWaiting ? l10n.parentFamilySetupWaitingTitle : l10n.parentFamilySetupGateTitle,
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: ParentColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isWaiting ? l10n.parentFamilySetupWaitingLead : l10n.parentFamilySetupGateLead,
                  style: GoogleFonts.onest(fontSize: 14, color: ParentColors.inkMuted, height: 1.45),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
                ],
                if (isWaiting && snapshot.pendingJoinUrl != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    l10n.parentFamilySetupShareLinkLabel,
                    style: GoogleFonts.onest(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ParentColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    snapshot.pendingJoinUrl!,
                    style: GoogleFonts.onest(fontSize: 13, color: ParentColors.ink),
                  ),
                  const SizedBox(height: 12),
                  AccountPrimaryButton(
                    label: l10n.parentFamilySetupCopyLink,
                    isLoading: _isPending,
                    onPressed: () => _copyLink(snapshot.pendingJoinUrl!),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _isPending ? null : () => _shareLink(snapshot.pendingJoinUrl!),
                    child: Text(l10n.parentFamilySetupShare),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isPending ? null : _cancelJoin,
                    child: Text(l10n.parentFamilySetupCancelJoin),
                  ),
                  if (_dedupAvailable && snapshot.pendingJoinToken != null) ...[
                    const SizedBox(height: 8),
                    AccountPrimaryButton(
                      label: l10n.parentFamilySetupResolveProfiles,
                      isLoading: _isPending,
                      onPressed: () {
                        final query =
                            'token=${Uri.encodeComponent(snapshot.pendingJoinToken!)}&kind=family-join-request';
                        context.go('/parent/family-join-dedup?$query');
                      },
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 20),
                  AccountPrimaryButton(
                    label: l10n.parentFamilySetupAnswerNo,
                    isLoading: _isPending,
                    onPressed: () => _answer('solo'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _isPending ? null : () => _answer('start_join'),
                    child: Text(l10n.parentFamilySetupAnswerYes),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
