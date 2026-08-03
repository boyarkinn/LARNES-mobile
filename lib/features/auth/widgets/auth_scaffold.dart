import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:larnes_mobile/app/theme/parent_text_theme.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_language_picker.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Morning Desk v4 shell for unauthenticated flows (login, register, reset).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.showBackButton = false,
    this.onBack,
    this.centerContent = false,
  });

  final String title;
  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;

  /// Vertically centers [child] — login screen only.
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(textTheme: buildParentTextTheme()),
      child: ParentParchmentBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AuthPageHeader(
                title: title,
                showBack: showBackButton,
                onBack: onBack,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final padding = AccountDeskMetrics.shellPadding;
                    final content = ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ParentChildCardMetrics.pickerMaxWidth,
                      ),
                      child: child,
                    );

                    return SingleChildScrollView(
                      padding: padding,
                      child: centerContent
                          ? ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight:
                                    constraints.maxHeight - padding.vertical,
                              ),
                              child: Center(child: content),
                            )
                          : Center(child: content),
                    );
                  },
                ),
              ),
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

class _AuthPageHeader extends StatelessWidget {
  const _AuthPageHeader({
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
                    padding: EdgeInsets.symmetric(horizontal: sideInset),
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
                      child: _AuthHeaderBackButton(
                        semanticsLabel: context.l10n.parentBack,
                        onPressed:
                            onBack ?? () => Navigator.of(context).maybePop(),
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

/// Step hint / subtitle under the page title (title lives in [AuthScaffold]).
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
