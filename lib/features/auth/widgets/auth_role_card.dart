import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/features/auth/auth_flow_labels.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/auth_flow_labels.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';

class AuthRoleCard extends StatefulWidget {
  const AuthRoleCard({
    super.key,
    required this.accountType,
    required this.onTap,
  });

  final RegisterAccountType accountType;
  final VoidCallback onTap;

  @override
  State<AuthRoleCard> createState() => _AuthRoleCardState();
}

class _AuthRoleCardState extends State<AuthRoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.accountType.hubRoleLabel(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: AuthMotion.tapDuration,
        curve: AuthMotion.curve,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AuthColors.surfaceStrong,
            borderRadius: BorderRadius.circular(AuthRadii.input),
            border: Border.all(color: const Color.fromRGBO(26, 29, 46, 0.12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                _RoleIcon(accountType: widget.accountType),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AuthColors.ink,
                      height: 1.25,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: AuthColors.muted.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleIcon extends StatelessWidget {
  const _RoleIcon({required this.accountType});

  final RegisterAccountType accountType;

  @override
  Widget build(BuildContext context) {
    final icon = switch (accountType) {
      RegisterAccountType.parent => Icons.person_outline_rounded,
      RegisterAccountType.teacher => Icons.school_outlined,
      RegisterAccountType.networkOwner => Icons.apartment_outlined,
    };

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AuthColors.cobaltSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: AuthColors.cobaltDeep),
    );
  }
}
