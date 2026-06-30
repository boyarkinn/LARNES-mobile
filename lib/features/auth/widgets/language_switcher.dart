import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class LanguageSwitcher extends StatefulWidget {
  const LanguageSwitcher({super.key});

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
    const menuWidth = 196.0;

    final selected = await showMenu<String>(
      context: context,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: LarnesColors.border),
      ),
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          bottomRight.dx - menuWidth,
          bottomRight.dy + 8,
          menuWidth,
          0,
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        _menuItem(
          value: 'ru',
          code: 'RU',
          label: l10n.languageRu,
          selected: current == 'ru',
        ),
        _menuItem(
          value: 'en',
          code: 'EN',
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
    required String code,
    required String label,
    required bool selected,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 52,
      padding: EdgeInsets.zero,
      child: _LanguageMenuTile(
        code: code,
        label: label,
        selected: selected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = LocaleScope.of(context).locale.languageCode.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        key: _anchorKey,
        color: Colors.transparent,
        child: InkWell(
          onTap: _openMenu,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LarnesColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: LarnesColors.coral.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.language_rounded,
                    size: 16,
                    color: LarnesColors.coral,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  current,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: LarnesColors.textPrimary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: LarnesColors.textSecondary.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageMenuTile extends StatelessWidget {
  const _LanguageMenuTile({
    required this.code,
    required this.label,
    required this.selected,
  });

  final String code;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? LarnesColors.coral.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? LarnesColors.coral.withValues(alpha: 0.16)
                      : LarnesColors.border.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? LarnesColors.coral : LarnesColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? LarnesColors.textPrimary
                        : LarnesColors.textSecondary,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: LarnesColors.teal,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
