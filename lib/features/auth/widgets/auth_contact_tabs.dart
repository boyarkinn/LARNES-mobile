import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';

class AuthContactTabs<T extends Object> extends StatelessWidget {
  const AuthContactTabs({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<AuthContactTabOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFECE8E1),
        borderRadius: BorderRadius.circular(AuthRadii.input),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (var index = 0; index < options.length; index++) ...[
              if (index > 0) const SizedBox(width: 4),
              Expanded(
                child: _AuthContactTabTile(
                  label: options[index].label,
                  selected: options[index].value == value,
                  onTap: () => onChanged(options[index].value),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AuthContactTabOption<T extends Object> {
  const AuthContactTabOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _AuthContactTabTile extends StatefulWidget {
  const _AuthContactTabTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AuthContactTabTile> createState() => _AuthContactTabTileState();
}

class _AuthContactTabTileState extends State<_AuthContactTabTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: AuthMotion.tapDuration,
        curve: AuthMotion.curve,
        child: AnimatedContainer(
          duration: AuthMotion.duration,
          curve: AuthMotion.curve,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.selected ? AuthColors.surfaceStrong : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: widget.selected
                ? const [
                    BoxShadow(
                      color: Color.fromRGBO(26, 29, 46, 0.09),
                      blurRadius: 7,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.selected ? AuthColors.ink : AuthColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
