import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';

class AccountSection extends StatelessWidget {
  const AccountSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: LarnesColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DecoratedBox(
          decoration: parentCardDecoration(),
          child: child,
        ),
      ],
    );
  }
}

class AccountDivider extends StatelessWidget {
  const AccountDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: LarnesColors.border);
  }
}

class AccountFieldRow extends StatelessWidget {
  const AccountFieldRow({
    super.key,
    required this.label,
    required this.value,
    this.muted = false,
    this.badgeLabel,
    this.badgeVerified,
  });

  final String label;
  final String value;
  final bool muted;
  final String? badgeLabel;
  final bool? badgeVerified;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: LarnesColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (badgeLabel != null) ...[
                  _ContactBadge(label: badgeLabel!, verified: badgeVerified ?? false),
                  const SizedBox(height: 4),
                ],
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: muted ? LarnesColors.textSecondary : LarnesColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountActionRow extends StatelessWidget {
  const AccountActionRow({
    super.key,
    required this.label,
    this.subtitle,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Colors.red.shade700
        : (enabled ? LarnesColors.textPrimary : LarnesColors.textSecondary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(color: color, fontSize: 14),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: LarnesColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (enabled)
                Icon(Icons.chevron_right, color: destructive ? Colors.red.shade300 : LarnesColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountLabeledRow extends StatelessWidget {
  const AccountLabeledRow({
    super.key,
    required this.label,
    this.value,
    this.hint,
  });

  final String label;
  final String? value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: LarnesColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (value != null) ...[
            const SizedBox(height: 2),
            Text(
              value!,
              style: const TextStyle(
                color: LarnesColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: const TextStyle(
                color: LarnesColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactBadge extends StatelessWidget {
  const _ContactBadge({required this.label, required this.verified});

  final String label;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final bg = verified ? const Color(0xFFECFDF3) : const Color(0xFFFFFBEB);
    final border = verified ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A);
    final text = verified ? const Color(0xFF15803D) : const Color(0xFFB45309);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
