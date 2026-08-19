import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AuthPublicHeader extends StatelessWidget {
  const AuthPublicHeader({
    super.key,
    this.showBackButton = false,
    this.onBack,
  });

  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AuthColors.headerBg,
        border: const Border(bottom: BorderSide(color: Color(0xD1D8E0DC))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topPadding + 8, 20, 8),
        child: SizedBox(
          height: AuthMetrics.headerMinHeight - 16,
          child: Row(
            children: [
              if (showBackButton)
                _AuthHeaderBackButton(
                  semanticsLabel: context.l10n.parentBack,
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                )
              else
                SvgPicture.asset(
                  'assets/brand/logo-horizontal-blue.svg',
                  height: 28,
                  semanticsLabel: 'LARNES',
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthHeaderBackButton extends StatefulWidget {
  const _AuthHeaderBackButton({
    required this.semanticsLabel,
    required this.onPressed,
  });

  final String semanticsLabel;
  final VoidCallback onPressed;

  @override
  State<_AuthHeaderBackButton> createState() => _AuthHeaderBackButtonState();
}

class _AuthHeaderBackButtonState extends State<_AuthHeaderBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: AuthMotion.tapDuration,
          curve: AuthMotion.curve,
          child: const Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: AuthColors.cobaltDeep,
          ),
        ),
      ),
    );
  }
}

class AuthCompactKicker extends StatelessWidget {
  const AuthCompactKicker({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
          height: 1.05,
          color: AuthColors.cobalt,
        ),
      ),
    );
  }
}

class AuthFormFoot extends StatelessWidget {
  const AuthFormFoot({
    super.key,
    required this.leadText,
    required this.linkLabel,
    required this.onLinkPressed,
  });

  final String leadText;
  final String linkLabel;
  final VoidCallback? onLinkPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: Text.rich(
          TextSpan(
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: AuthColors.muted,
            ),
            children: [
              TextSpan(text: '$leadText '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: onLinkPressed,
                  child: Text(
                    linkLabel,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AuthColors.cobaltDeep,
                    ),
                  ),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
