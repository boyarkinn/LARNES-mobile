import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/child_classroom_qr.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:share_plus/share_plus.dart';

/// QR для класса на профиле ребёнка (web `ChildClassroomQrCard`).
class ChildClassroomQrCard extends StatefulWidget {
  const ChildClassroomQrCard({
    super.key,
    required this.childId,
    required this.childName,
    required this.tokens,
  });

  final String childId;
  final String childName;
  final ChildCardColorTokens tokens;

  @override
  ChildClassroomQrCardState createState() => ChildClassroomQrCardState();
}

class ChildClassroomQrCardState extends State<ChildClassroomQrCard> {
  bool _isLoading = true;
  bool _isPending = false;
  String? _error;
  ChildClassroomQrState? _state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        reload();
      }
    });
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final state = await AuthScope.of(context).parentApi.fetchChildClassroomQr(
            widget.childId,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _state = state;
        _isLoading = false;
      });
    } on ParentApiException catch (error) {
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

  Future<void> _mutate(ChildClassroomQrAction action) async {
    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final state = await AuthScope.of(context).parentApi.mutateChildClassroomQr(
            childId: widget.childId,
            action: action,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _state = state;
        _isPending = false;
      });
    } on ParentApiException catch (error) {
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

  Future<void> _confirmRegenerate() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.parentClassroomQrConfirmRegenerateTitle),
        content: Text(l10n.parentClassroomQrConfirmRegenerateMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.parentClassroomQrCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.parentClassroomQrRegenerate),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _mutate(ChildClassroomQrAction.regenerate);
    }
  }

  Future<void> _confirmRevoke() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.parentClassroomQrConfirmRevokeTitle),
        content: Text(l10n.parentClassroomQrConfirmRevokeMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.parentClassroomQrCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.parentClassroomQrRevoke),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _mutate(ChildClassroomQrAction.revoke);
    }
  }

  Future<void> _shareQr() async {
    final qrDataUrl = _state?.qrDataUrl;
    if (qrDataUrl == null) {
      return;
    }

    final bytes = decodeQrDataUrl(qrDataUrl);
    if (bytes == null) {
      return;
    }

    final l10n = context.l10n;
    final version = _state?.version;
    final versionLabel = version != null ? l10n.parentClassroomQrVersion(version) : null;
    final text = versionLabel != null
        ? '${widget.childName}\n$versionLabel'
        : widget.childName;

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
          ),
        ],
        fileNameOverrides: const ['classroom-qr.png'],
        text: text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AccountDeskCard(
      bandTitle: l10n.parentClassroomQrTitle,
      tokens: widget.tokens,
      child: Padding(
        padding: AccountDeskMetrics.formPadding,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(color: ParentColors.shell),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildQrBody(l10n),
                  const SizedBox(height: 16),
                  _buildActions(l10n),
                ],
              ),
      ),
    );
  }

  Widget _buildQrBody(dynamic l10n) {
    final state = _state;

    if (_error != null && state == null) {
      return const SizedBox.shrink();
    }

    if (state?.active == true && state?.qrDataUrl != null) {
      final bytes = decodeQrDataUrl(state!.qrDataUrl!);
      return Column(
        children: [
          if (bytes != null)
            Image.memory(
              bytes,
              width: 176,
              height: 176,
              fit: BoxFit.contain,
              semanticLabel: l10n.parentClassroomQrAlt,
            )
          else
            const SizedBox(width: 176, height: 176),
          if (state.version != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.parentClassroomQrVersion(state.version!),
              style: const TextStyle(
                color: ParentColors.inkMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
    }

    if (state != null && !state.active) {
      return Text(
        l10n.parentClassroomQrRevokedHint,
        style: const TextStyle(color: ParentColors.inkMuted, fontSize: 14),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActions(dynamic l10n) {
    final active = _state?.active == true && _state?.qrDataUrl != null;

    if (active) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _isPending ? null : _shareQr,
            child: Text(l10n.parentClassroomQrPrint),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _isPending ? null : _confirmRegenerate,
            child: _isPending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.parentClassroomQrRegenerate),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _isPending ? null : _confirmRevoke,
            child: Text(l10n.parentClassroomQrRevoke),
          ),
        ],
      );
    }

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: ParentColors.shell,
        minimumSize: const Size.fromHeight(48),
      ),
      onPressed: _isPending ? null : () => _mutate(ChildClassroomQrAction.issue),
      child: _isPending
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(l10n.parentClassroomQrIssue),
    );
  }
}

/// Декодирует data URL QR в PNG bytes (для share).
Uint8List? decodeQrDataUrl(String dataUrl) {
  final comma = dataUrl.indexOf(',');
  if (comma < 0) {
    return null;
  }
  try {
    return base64Decode(dataUrl.substring(comma + 1));
  } catch (_) {
    return null;
  }
}
