import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/family_setup_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/account/desk_text_field.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_panel_error_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:share_plus/share_plus.dart';

/// Gate «Семья уже в LARNES?» — паритет с web `FamilySetupPanel`.
class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  bool _isLoading = true;
  bool _isPending = false;
  bool _dedupAvailable = false;
  bool _namingSolo = false;
  bool _showJoinLink = false;
  String? _error;
  FamilySetupSnapshot? _snapshot;
  final _displayNameController = TextEditingController();

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
    _displayNameController.dispose();
    super.dispose();
  }

  String? _requireDisplayName(AppLocalizations l10n) {
    final value = _displayNameController.text.trim();
    if (value.length < 2) {
      return l10n.parentFamilySetupDisplayNameRequired;
    }
    return null;
  }

  void _openNaming() {
    setState(() {
      _namingSolo = true;
      _showJoinLink = false;
      _error = null;
    });
  }

  void _closeNaming() {
    setState(() {
      _namingSolo = false;
      _error = null;
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
    final l10n = context.l10n;
    String? displayName;
    if (answer == 'solo') {
      final nameError = _requireDisplayName(l10n);
      if (nameError != null) {
        setState(() => _error = nameError);
        return;
      }
      displayName = _displayNameController.text.trim();
    }

    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final auth = AuthScope.of(context);
      final snapshot = await auth.familySetupApi.answer(
        answer: answer,
        displayName: displayName,
        locale: locale,
      );
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
        _namingSolo = false;
        _showJoinLink = false;
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
    final l10n = context.l10n;
    final nameError = _requireDisplayName(l10n);
    if (nameError != null) {
      setState(() => _error = nameError);
      return;
    }

    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final auth = AuthScope.of(context);
      final snapshot = await auth.familySetupApi.cancelJoin(
        displayName: _displayNameController.text.trim(),
        locale: locale,
      );
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

  Future<void> _logout() async {
    await AuthScope.of(context).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  String _headerTitle(AppLocalizations l10n, {required bool isWaiting}) {
    if (_namingSolo) {
      return l10n.parentFamilySetupSoloNameTitle;
    }
    if (isWaiting) {
      return l10n.parentFamilySetupWaitingTitle;
    }
    return l10n.parentFamilySetupGateTitle;
  }

  ButtonStyle get _ghostStyle => TextButton.styleFrom(
        foregroundColor: ParentColors.inkMuted,
        minimumSize: const Size.fromHeight(40),
        textStyle: GoogleFonts.onest(fontSize: 15, fontWeight: FontWeight.w500),
      );

  ButtonStyle get _secondaryStyle => OutlinedButton.styleFrom(
        foregroundColor: ParentColors.ink,
        backgroundColor: ParentColors.surface,
        side: const BorderSide(color: ParentColors.line),
        minimumSize: const Size.fromHeight(48),
        textStyle: GoogleFonts.onest(fontSize: 15, fontWeight: FontWeight.w600),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isWaiting = _snapshot?.isPendingJoin ?? false;

    return ParentScaffold(
      title: _headerTitle(l10n, isWaiting: isWaiting),
      showBack: false,
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading && _snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _snapshot == null) {
      return ParentPanelErrorPanel(
        message: _error!,
        onRetry: _load,
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
                  _namingSolo
                      ? l10n.parentFamilySetupSoloNameTitle
                      : isWaiting
                          ? l10n.parentFamilySetupWaitingTitle
                          : l10n.parentFamilySetupGateTitle,
                  style: GoogleFonts.fredoka(
                    fontSize: _namingSolo || isWaiting ? 22 : 24,
                    fontWeight: FontWeight.w600,
                    color: ParentColors.ink,
                    letterSpacing: 0,
                  ),
                ),
                if (!_namingSolo) ...[
                  SizedBox(height: isWaiting ? 0 : 8),
                  Text(
                    isWaiting
                        ? l10n.parentFamilySetupWaitingLead
                        : l10n.parentFamilySetupGateLead,
                    style: GoogleFonts.onest(
                      fontSize: 14,
                      color: ParentColors.inkMuted,
                      height: 1.45,
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
                ],
                if (_namingSolo)
                  _buildNamingStep(l10n, isWaiting: isWaiting)
                else if (isWaiting)
                  _buildWaitingStep(l10n, snapshot)
                else
                  _buildGateStep(l10n),
              ],
            ),
          ),
        ),
        AccountDeskCard(
          child: Padding(
            padding: AccountDeskMetrics.formPadding,
            child: TextButton(
              onPressed: _isPending ? null : _logout,
              child: Text(l10n.logoutButton),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNamingStep(AppLocalizations l10n, {required bool isWaiting}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        TextField(
          controller: _displayNameController,
          enabled: !_isPending,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.onest(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: ParentColors.ink,
          ),
          decoration: DeskTextField.inputDecoration(
            hintText: l10n.parentFamilySetupDisplayNamePlaceholder,
          ).copyWith(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
        AccountPrimaryButton(
          label: l10n.parentFamilySetupCreateSolo,
          isLoading: _isPending,
          onPressed: isWaiting ? _cancelJoin : () => _answer('solo'),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _isPending ? null : _closeNaming,
          style: _ghostStyle,
          child: Text(l10n.parentFamilySetupBack),
        ),
      ],
    );
  }

  Widget _buildWaitingStep(AppLocalizations l10n, FamilySetupSnapshot snapshot) {
    final url = snapshot.pendingJoinUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (url != null) ...[
          const SizedBox(height: 16),
          AccountPrimaryButton(
            label: l10n.parentFamilySetupCopyLink,
            isLoading: _isPending,
            onPressed: () => _copyLink(url),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _isPending
                ? null
                : () => setState(() => _showJoinLink = !_showJoinLink),
            style: _ghostStyle,
            child: Text(
              _showJoinLink
                  ? l10n.parentFamilySetupHideLink
                  : l10n.parentFamilySetupShowLink,
            ),
          ),
          if (_showJoinLink) ...[
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: ParentColors.shellSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ParentColors.line),
              ),
              child: SelectableText(
                url,
                style: GoogleFonts.onest(
                  fontSize: 12,
                  height: 1.45,
                  color: ParentColors.ink,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          OutlinedButton(
            onPressed: _isPending ? null : () => _shareLink(url),
            style: _secondaryStyle,
            child: Text(l10n.parentFamilySetupShare),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isPending ? null : _openNaming,
          style: _ghostStyle,
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
      ],
    );
  }

  Widget _buildGateStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        AccountPrimaryButton(
          label: l10n.parentFamilySetupAnswerNo,
          isLoading: _isPending,
          onPressed: _openNaming,
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _isPending ? null : () => _answer('start_join'),
          style: _secondaryStyle,
          child: Text(l10n.parentFamilySetupAnswerYes),
        ),
      ],
    );
  }
}
