import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';

class AdminAccountMetrics {
  const AdminAccountMetrics._();

  static const shellPadding = EdgeInsets.fromLTRB(16, 16, 16, 32);
  static const cardGap = 16.0;
  static const rowPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const formPadding = EdgeInsets.fromLTRB(16, 16, 16, 20);
  static const maxWidth = 480.0;
}

class AdminAccountShell extends StatelessWidget {
  const AdminAccountShell({
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
      padding: AdminAccountMetrics.shellPadding,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AdminAccountMetrics.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _withGap(children, AdminAccountMetrics.cardGap),
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

class AdminAccountCard extends StatelessWidget {
  const AdminAccountCard({
    super.key,
    this.title,
    required this.child,
  });

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text(
                title!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.02,
                  color: AdminColors.inkMuted,
                ),
              ),
            ),
          if (title != null) const Divider(height: 1, color: AdminColors.line),
          child,
        ],
      ),
    );
  }
}

class AdminAccountFormShell extends StatelessWidget {
  const AdminAccountFormShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AdminAccountShell(
      children: [
        AdminAccountCard(
          child: Padding(
            padding: AdminAccountMetrics.formPadding,
            child: child,
          ),
        ),
      ],
    );
  }
}

class AdminAccountDivider extends StatelessWidget {
  const AdminAccountDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AdminColors.line);
  }
}

class AdminAccountFieldGroup extends StatelessWidget {
  const AdminAccountFieldGroup({
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
    return _AdminTapRow(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.ink,
                        ),
                      ),
                    ),
                    if (badgeLabel != null) ...[
                      const SizedBox(width: 8),
                      AdminContactBadge(
                        label: badgeLabel!,
                        verified: badgeVerified ?? false,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: valueMuted ? AdminColors.inkMuted : AdminColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const _Chevron(),
        ],
      ),
    );
  }
}

class AdminContactBadge extends StatelessWidget {
  const AdminContactBadge({
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
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}

class AdminAccountPrimaryButton extends StatelessWidget {
  const AdminAccountPrimaryButton({
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
        backgroundColor: AdminColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label),
    );
  }
}

class AdminAccountDestructiveButton extends StatelessWidget {
  const AdminAccountDestructiveButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  static const _red = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return _AdminTapRow(
      onTap: onTap,
      child: ColoredBox(
        color: filled ? _red : Colors.transparent,
        child: Padding(
          padding: AdminAccountMetrics.rowPadding,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
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

class _AdminTapRow extends StatelessWidget {
  const _AdminTapRow({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: AdminAccountMetrics.rowPadding, child: child),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return Text(
      '›',
      style: GoogleFonts.inter(
        fontSize: 18,
        height: 1,
        color: AdminColors.inkMuted,
      ),
    );
  }
}
