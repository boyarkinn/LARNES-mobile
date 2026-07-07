import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

enum LanguageSwitcherVariant { auth, parent }

class LanguageSwitcher extends StatefulWidget {
  const LanguageSwitcher({
    super.key,
    this.variant = LanguageSwitcherVariant.auth,
  });

  final LanguageSwitcherVariant variant;

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  final _anchorKey = GlobalKey();

  Future<void> _openMenu() async {
    final controller = LocaleScope.of(context);
    final l10n = context.l10n;
    final current = controller.locale.languageCode;
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final bottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    const menuWidth = 188.0;

    final selected = await showMenu<String>(
      context: context,
      elevation: 0,
      color: ParentColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: ParentColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ParentRadii.card),
        side: const BorderSide(color: ParentColors.line),
      ),
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          bottomRight.dx - menuWidth,
          bottomRight.dy + 6,
          menuWidth,
          0,
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        _menuItem(
          value: 'ru',
          label: l10n.languageRu,
          selected: current == 'ru',
        ),
        _menuItem(
          value: 'en',
          label: l10n.languageEn,
          selected: current == 'en',
        ),
      ],
    );

    if (selected != null && mounted) {
      await controller.setLocale(Locale(selected));
    }
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required String label,
    required bool selected,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 46,
      padding: EdgeInsets.zero,
      child: _DeskLanguageMenuTile(
        label: label,
        selected: selected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DeskLanguageSwitcherButton(onTap: _openMenu, anchorKey: _anchorKey);
  }
}

class _DeskLanguageSwitcherButton extends StatefulWidget {
  const _DeskLanguageSwitcherButton({
    required this.onTap,
    required this.anchorKey,
  });

  final VoidCallback onTap;
  final GlobalKey anchorKey;

  @override
  State<_DeskLanguageSwitcherButton> createState() => _DeskLanguageSwitcherButtonState();
}

class _DeskLanguageSwitcherButtonState extends State<_DeskLanguageSwitcherButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final current = LocaleScope.of(context).locale.languageCode.toUpperCase();

    return GestureDetector(
      key: widget.anchorKey,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: ParentMotion.tapDuration,
        curve: ParentMotion.curve,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ParentColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _pressed ? ParentColors.shell : ParentColors.line,
            ),
            boxShadow: const [
              BoxShadow(
                color: ParentColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  current,
                  style: GoogleFonts.onest(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ParentColors.shellDeep,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: ParentColors.shellDeep.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeskLanguageMenuTile extends StatelessWidget {
  const _DeskLanguageMenuTile({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? ParentColors.shellSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: selected
                  ? Text(
                      '✓',
                      style: GoogleFonts.onest(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ParentColors.shell,
                        height: 1,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.onest(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? ParentColors.shellDeep : ParentColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
