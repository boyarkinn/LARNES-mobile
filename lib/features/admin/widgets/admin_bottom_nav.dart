import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/features/admin/navigation/admin_navigation.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({
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
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(top: BorderSide(color: AdminColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavIcon(
                selected: currentIndex == AdminNavigation.trainersTabIndex,
                icon: Icons.extension_outlined,
                selectedIcon: Icons.extension,
                semanticsLabel: l10n.adminNavTrainers,
                onTap: () => onDestinationSelected(AdminNavigation.trainersTabIndex),
              ),
              _NavIcon(
                selected: currentIndex == AdminNavigation.accountTabIndex,
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                semanticsLabel: l10n.adminNavAccount,
                onTap: () => onDestinationSelected(AdminNavigation.accountTabIndex),
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
    final color = widget.selected ? AdminColors.accent : AdminColors.inkMuted;

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
            duration: AdminMotion.tapDuration,
            curve: AdminMotion.curve,
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
