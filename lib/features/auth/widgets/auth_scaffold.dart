import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:larnes_mobile/app/theme/parent_text_theme.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/auth/theme/auth_text_theme.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_background.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_language_picker.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_legal_footer.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

enum AuthScaffoldVariant { web, legacy }

/// Auth page shell — [AuthScaffoldVariant.web] matches web `auth.css` @760px.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.variant = AuthScaffoldVariant.legacy,
    this.title,
    this.showBackButton = false,
    this.onBack,
    this.centerContent = false,
  });

  final Widget child;
  final AuthScaffoldVariant variant;
  final String? title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool centerContent;

  static EdgeInsets _scrollPadding({
    required EdgeInsets base,
    required double keyboardInset,
  }) {
    return base.copyWith(bottom: base.bottom + keyboardInset);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardVisible = keyboardInset > 0;

    if (variant == AuthScaffoldVariant.web) {
      return Theme(
        data: Theme.of(context).copyWith(textTheme: buildAuthTextTheme()),
        child: AuthBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthPublicHeader(
                  showBackButton: showBackButton,
                  onBack: onBack,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const basePadding = EdgeInsets.fromLTRB(
                        AuthMetrics.horizontalPadding,
                        24,
                        AuthMetrics.horizontalPadding,
                        16,
                      );
                      final padding = _scrollPadding(
                        base: basePadding,
                        keyboardInset: keyboardInset,
                      );
                      final content = ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AuthMetrics.formMaxWidth,
                        ),
                        child: child,
                      );

                      return SingleChildScrollView(
                        padding: padding,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: centerContent
                            ? ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight - padding.vertical,
                                ),
                                child: Center(child: content),
                              )
                            : Align(alignment: Alignment.topCenter, child: content),
                      );
                    },
                  ),
                ),
                if (!keyboardVisible)
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Center(child: AuthLanguageFooterLink()),
                        AuthLegalFooter(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(textTheme: buildParentTextTheme()),
      child: ParentParchmentBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LegacyAuthPageHeader(
                title: title ?? '',
                showBack: showBackButton,
                onBack: onBack,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final basePadding = AccountDeskMetrics.shellPadding;
                    final padding = _scrollPadding(
                      base: basePadding,
                      keyboardInset: keyboardInset,
                    );
                    final content = ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ParentChildCardMetrics.pickerMaxWidth,
                      ),
                      child: child,
                    );

                    return SingleChildScrollView(
                      padding: padding,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: centerContent
                          ? ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - padding.vertical,
                              ),
                              child: Center(child: content),
                            )
                          : Center(child: content),
                    );
                  },
                ),
              ),
              if (!keyboardVisible)
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: 8),
                  child: Center(child: AuthLanguageFooterLink()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegacyAuthPageHeader extends StatelessWidget {
  const _LegacyAuthPageHeader({
    required this.title,
    required this.showBack,
    this.onBack,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = buildParentTextTheme();
    final topPadding = MediaQuery.paddingOf(context).top;
    const sideInset = 48.0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ParentColors.surface.withValues(alpha: 0.88),
            border: const Border(bottom: BorderSide(color: ParentColors.line)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 12),
            child: SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: sideInset),
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: ParentColors.shell,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (showBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _LegacyAuthHeaderBackButton(
                        semanticsLabel: context.l10n.parentBack,
                        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SvgPicture.asset(
                        'assets/brand/mark-blue.svg',
                        width: 32,
                        height: 32,
                        semanticsLabel: 'LARNES',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegacyAuthHeaderBackButton extends StatefulWidget {
  const _LegacyAuthHeaderBackButton({
    required this.semanticsLabel,
    required this.onPressed,
  });

  final String semanticsLabel;
  final VoidCallback onPressed;

  @override
  State<_LegacyAuthHeaderBackButton> createState() =>
      _LegacyAuthHeaderBackButtonState();
}

class _LegacyAuthHeaderBackButtonState extends State<_LegacyAuthHeaderBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: ParentMotion.tapDuration,
          curve: ParentMotion.curve,
          child: const Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: ParentColors.shell,
          ),
        ),
      ),
    );
  }
}

/// Step hint / subtitle under the page title (legacy shell title lives in header).
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    if (subtitle == null || subtitle!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

/// Secondary body copy under step subtitle (hints, instructions).
class AuthBodyHint extends StatelessWidget {
  const AuthBodyHint({
    super.key,
    required this.text,
    this.padding = const EdgeInsets.only(bottom: 16),
  });

  final String text;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

/// Muted helper copy (cooldown timers, footnotes).
class AuthMutedText extends StatelessWidget {
  const AuthMutedText({
    super.key,
    required this.text,
    this.textAlign = TextAlign.center,
    this.padding = EdgeInsets.zero,
  });

  final String text;
  final TextAlign textAlign;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text,
        textAlign: textAlign,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.35),
      ),
    );
  }
}
