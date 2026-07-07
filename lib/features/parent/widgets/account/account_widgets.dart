import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/theme/hub_card_appearance.dart';

/// Размеры account desk (web `.parent-account-desk-*`, mobile).
class AccountDeskMetrics {
  const AccountDeskMetrics._();

  static const shellPadding = EdgeInsets.fromLTRB(16, 22, 16, 36);
  static const cardGap = 18.0; // 1.125rem
  static const bandMinHeight = 42.0; // 2.625rem
  static const rowPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 13);
  static const formPadding = EdgeInsets.fromLTRB(16, 16, 16, 20);
}

/// Scroll-оболочка account-страниц.
class AccountDeskShell extends StatelessWidget {
  const AccountDeskShell({
    super.key,
    required this.children,
    this.refreshIndicator,
  });

  final List<Widget> children;
  final Future<void> Function()? refreshIndicator;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: refreshIndicator != null
          ? const AlwaysScrollableScrollPhysics()
          : null,
      padding: AccountDeskMetrics.shellPadding,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ParentChildCardMetrics.pickerMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _withGap(children, AccountDeskMetrics.cardGap),
            ),
          ),
        ),
      ],
    );

    if (refreshIndicator == null) {
      return list;
    }

    return RefreshIndicator(onRefresh: refreshIndicator!, child: list);
  }

  List<Widget> _withGap(List<Widget> items, double gap) {
    if (items.isEmpty) {
      return items;
    }
    final result = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      result
        ..add(SizedBox(height: gap))
        ..add(items[i]);
    }
    return result;
  }
}

/// Desk-карточка с band (Morning Desk v4).
class AccountDeskCard extends StatelessWidget {
  const AccountDeskCard({
    super.key,
    this.bandTitle,
    required this.child,
    this.tokens = profileHubCardTokens,
  });

  final String? bandTitle;
  final Widget child;
  final ChildCardColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ParentRadii.card),
      child: DecoratedBox(
        decoration: parentCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bandTitle != null) _Band(title: bandTitle!, tokens: tokens),
            child,
          ],
        ),
      ),
    );
  }
}

/// Одна desk-карточка для form sub-страниц.
class AccountDeskFormShell extends StatelessWidget {
  const AccountDeskFormShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AccountDeskShell(
      children: [
        AccountDeskCard(
          child: Padding(
            padding: AccountDeskMetrics.formPadding,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.title, required this.tokens});

  final String title;
  final ChildCardColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AccountDeskMetrics.bandMinHeight),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: tokens.tag,
      ),
      foregroundDecoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.03),
          ],
          stops: const [0.7, 1],
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01 * 16,
          height: 1.2,
          color: ParentColors.surface,
        ),
      ),
    );
  }
}

class AccountDivider extends StatelessWidget {
  const AccountDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: ParentColors.line.withValues(alpha: 0.85));
  }
}

/// Поле аккаунта — 2 строки: label (+ badge) сверху, value слева снизу.
class AccountFieldGroup extends StatelessWidget {
  const AccountFieldGroup({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.valueMuted = false,
    this.badgeLabel,
    this.badgeVerified,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool valueMuted;
  final String? badgeLabel;
  final bool? badgeVerified;

  @override
  Widget build(BuildContext context) {
    return _AccountTapRow(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.onest(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ParentColors.ink,
                        ),
                      ),
                    ),
                    if (badgeLabel != null) ...[
                      const SizedBox(width: 8),
                      AccountContactBadge(
                        label: badgeLabel!,
                        verified: badgeVerified ?? false,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.onest(
                    fontSize: 14,
                    color: valueMuted ? ParentColors.inkMuted : ParentColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: _Chevron(),
          ),
        ],
      ),
    );
  }
}

/// Destructive row in account security (web `.parent-account-destructive-btn`).
class AccountDestructiveButton extends StatelessWidget {
  const AccountDestructiveButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;

  /// Web: `parent-account-destructive-btn--filled` — белый текст на красном фоне.
  final bool filled;

  static const _red = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return ParentScaleTap(
      onTap: onTap,
      child: ColoredBox(
        color: filled ? _red : Colors.transparent,
        child: Padding(
          padding: AccountDeskMetrics.rowPadding,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.onest(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : _red,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Строка-ссылка (add child, logout).
class AccountLinkRow extends StatelessWidget {
  const AccountLinkRow({
    super.key,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFB91C1C)
        : (enabled ? ParentColors.ink : ParentColors.inkMuted);

    return _AccountTapRow(
      onTap: enabled ? onTap : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.onest(fontSize: 14, fontWeight: FontWeight.w600, color: color),
            ),
          ),
          if (enabled) _Chevron(color: destructive ? const Color(0xFFFCA5A5) : null),
        ],
      ),
    );
  }
}

/// Строка ребёнка в списке account.
class AccountChildRow extends StatelessWidget {
  const AccountChildRow({
    super.key,
    required this.name,
    this.meta,
    required this.onTap,
  });

  final String name;
  final String? meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AccountTapRow(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.onest(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ParentColors.ink,
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta!,
                    style: GoogleFonts.onest(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ParentColors.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const _Chevron(),
        ],
      ),
    );
  }
}

/// Read-only строка (education blocks).
class AccountInfoRow extends StatelessWidget {
  const AccountInfoRow({
    super.key,
    required this.label,
    this.value,
    this.hint,
    this.valueMuted = false,
  });

  final String label;
  final String? value;
  final String? hint;
  final bool valueMuted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AccountDeskMetrics.rowPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.onest(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ParentColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (value != null)
                  Text(
                    value!,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.onest(
                      fontSize: 14,
                      color: valueMuted ? ParentColors.inkMuted : ParentColors.ink,
                    ),
                  ),
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    hint!,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.onest(fontSize: 12, color: ParentColors.inkMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountEmptyText extends StatelessWidget {
  const AccountEmptyText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AccountDeskMetrics.rowPadding,
      child: Text(
        text,
        style: GoogleFonts.onest(fontSize: 14, color: ParentColors.inkMuted),
      ),
    );
  }
}

class AccountContactBadge extends StatelessWidget {
  const AccountContactBadge({
    super.key,
    required this.label,
    required this.verified,
  });

  final String label;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final colors = verified
        ? (
            border: const Color.fromRGBO(16, 185, 129, 0.35),
            background: const Color.fromRGBO(16, 185, 129, 0.1),
            text: const Color(0xFF047857),
          )
        : (
            border: const Color.fromRGBO(245, 158, 11, 0.35),
            background: const Color.fromRGBO(245, 158, 11, 0.1),
            text: const Color(0xFFB45309),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: GoogleFonts.onest(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}

class AccountPrimaryButton extends StatelessWidget {
  const AccountPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: ParentColors.shell,
        minimumSize: const Size.fromHeight(48),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label),
    );
  }
}

class _AccountTapRow extends StatelessWidget {
  const _AccountTapRow({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return Padding(padding: AccountDeskMetrics.rowPadding, child: child);
    }

    return ParentScaleTap(
      onTap: onTap!,
      child: Padding(padding: AccountDeskMetrics.rowPadding, child: child),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '›',
      style: TextStyle(
        fontSize: 18,
        height: 1,
        color: color ?? ParentColors.lineHover,
      ),
    );
  }
}
