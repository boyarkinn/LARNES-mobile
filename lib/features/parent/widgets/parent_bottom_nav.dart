import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/navigation/parent_navigation.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class ParentBottomNav extends StatelessWidget {
  const ParentBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ParentColors.surface.withValues(alpha: 0.94),
        border: Border(top: BorderSide(color: ParentColors.line.withValues(alpha: 0.9))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavIcon(
                selected: currentIndex == ParentNavigation.childrenTabIndex,
                icon: Icons.family_restroom_outlined,
                selectedIcon: Icons.family_restroom,
                semanticsLabel: l10n.parentChildPickerTitle,
                onTap: () => onDestinationSelected(ParentNavigation.childrenTabIndex),
              ),
              _NavIcon(
                selected: currentIndex == ParentNavigation.accountTabIndex,
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                semanticsLabel: l10n.parentAccountTitle,
                onTap: () => onDestinationSelected(ParentNavigation.accountTabIndex),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatefulWidget {
  const _NavIcon({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.semanticsLabel,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  State<_NavIcon> createState() => _NavIconState();
}

class _NavIconState extends State<_NavIcon> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? ParentColors.shell : ParentColors.inkMuted;

    return Expanded(
      child: Semantics(
        button: true,
        label: widget.semanticsLabel,
        selected: widget.selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: ParentMotion.tapDuration,
            curve: ParentMotion.curve,
            child: Icon(
              widget.selected ? widget.selectedIcon : widget.icon,
              size: 26,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
