import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/family_join_dedup_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class FamilyJoinDedupScreen extends StatefulWidget {
  const FamilyJoinDedupScreen({
    super.key,
    required this.token,
    required this.kind,
  });

  final String token;
  final String kind;

  @override
  State<FamilyJoinDedupScreen> createState() => _FamilyJoinDedupScreenState();
}

class _FamilyJoinDedupScreenState extends State<FamilyJoinDedupScreen> {
  bool _isLoading = true;
  bool _isPending = false;
  String? _error;
  FamilyJoinDedupContext? _context;
  _DedupStep _step = _DedupStep.choice;

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
    if (widget.token.isEmpty || widget.kind.isEmpty) {
      setState(() {
        _error = context.l10n.parentFamilyJoinDedupInvalidLead;
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
      final contextData = await AuthScope.of(context).familyJoinDedupApi.fetchContext(
            token: widget.token,
            kind: widget.kind,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      if (contextData == null) {
        setState(() {
          _error = context.l10n.parentFamilyJoinDedupInvalidLead;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _context = contextData;
        _isLoading = false;
      });
    } on FamilyJoinDedupApiException catch (error) {
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

  Future<void> _finishResolve(FamilyJoinDedupResolveResult result) async {
    if (result.completed) {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).refreshFamilySetup(locale: locale);
      if (!mounted) {
        return;
      }
      context.go('/parent');
      return;
    }

    if (result.next != null) {
      setState(() {
        _context = result.next;
        _step = _DedupStep.choice;
        _isPending = false;
      });
    }
  }

  Future<void> _chooseDifferentChildren() async {
    final contextData = _context;
    if (contextData == null) {
      return;
    }

    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final result = await AuthScope.of(context).familyJoinDedupApi.resolveDifferentChildren(
            token: contextData.token,
            kind: contextData.kind,
            normalizedFirstName: contextData.normalizedFirstName,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      await _finishResolve(result);
    } on FamilyJoinDedupApiException catch (error) {
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

  Future<void> _pickKeeper(String keeperChildId) async {
    final contextData = _context;
    if (contextData == null) {
      return;
    }

    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final result = await AuthScope.of(context).familyJoinDedupApi.resolvePickKeeper(
            token: contextData.token,
            kind: contextData.kind,
            normalizedFirstName: contextData.normalizedFirstName,
            keeperChildId: keeperChildId,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      await _finishResolve(result);
    } on FamilyJoinDedupApiException catch (error) {
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

  String _formatDate(DateTime value) {
    final locale = LocaleScope.of(context).localeCode;
    return DateFormat.yMMMd(locale).format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final contextData = _context;

    return ParentScaffold(
      title: _step == _DedupStep.choice
          ? l10n.parentFamilyJoinDedupChoiceTitle(contextData?.displayFirstName ?? '')
          : l10n.parentFamilyJoinDedupPickTitle,
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(dynamic l10n) {
    if (_isLoading && _context == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _context == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.parentFamilyJoinDedupInvalidTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: ParentColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.onest(fontSize: 14, color: ParentColors.inkMuted),
              ),
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

    final contextData = _context!;

    return AccountDeskShell(
      children: [
        AccountDeskCard(
          child: Padding(
            padding: AccountDeskMetrics.formPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _step == _DedupStep.choice
                      ? l10n.parentFamilyJoinDedupChoiceTitle(contextData.displayFirstName)
                      : l10n.parentFamilyJoinDedupPickTitle,
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: ParentColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _step == _DedupStep.choice
                      ? l10n.parentFamilyJoinDedupChoiceLead
                      : l10n.parentFamilyJoinDedupPickLead,
                  style: GoogleFonts.onest(fontSize: 14, color: ParentColors.inkMuted, height: 1.45),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
                ],
                const SizedBox(height: 20),
                if (_step == _DedupStep.choice) ...[
                  AccountPrimaryButton(
                    label: l10n.parentFamilyJoinDedupDifferentChildren,
                    isLoading: _isPending,
                    onPressed: _chooseDifferentChildren,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _isPending ? null : () => setState(() => _step = _DedupStep.pick),
                    child: Text(l10n.parentFamilyJoinDedupSameChild),
                  ),
                ] else ...[
                  _buildChildCard(contextData.sourceChild, l10n),
                  const SizedBox(height: 12),
                  _buildChildCard(contextData.targetChild, l10n),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isPending ? null : () => setState(() => _step = _DedupStep.choice),
                    child: Text(l10n.parentFamilyJoinDedupBack),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChildCard(FamilyJoinDedupChildCard card, dynamic l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: ParentColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            card.fullName,
            style: GoogleFonts.onest(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ParentColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.parentFamilyJoinDedupRegisteredLabel}: ${_formatDate(card.createdAt)}',
            style: GoogleFonts.onest(fontSize: 13, color: ParentColors.inkMuted),
          ),
          if (card.networkHint != null) ...[
            const SizedBox(height: 2),
            Text(
              '${l10n.parentFamilyJoinDedupNetworkLabel}: ${card.networkHint}',
              style: GoogleFonts.onest(fontSize: 13, color: ParentColors.inkMuted),
            ),
          ],
          if (card.programHint != null) ...[
            const SizedBox(height: 2),
            Text(
              '${l10n.parentFamilyJoinDedupProgramLabel}: ${card.programHint}',
              style: GoogleFonts.onest(fontSize: 13, color: ParentColors.inkMuted),
            ),
          ],
          const SizedBox(height: 12),
          AccountPrimaryButton(
            label: l10n.parentFamilyJoinDedupKeepProfile,
            isLoading: _isPending,
            onPressed: () => _pickKeeper(card.childId),
          ),
        ],
      ),
    );
  }
}

enum _DedupStep { choice, pick }
