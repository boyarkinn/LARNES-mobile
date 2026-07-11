import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';

/// Shared action buttons for letter-color and letter-case-color pads.
class ColorLetterActionButton extends StatelessWidget {
  const ColorLetterActionButton({
    super.key,
    required this.disabled,
    required this.filled,
    required this.label,
    required this.onPressed,
  });

  final bool disabled;
  final bool filled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Material(
        color: filled
            ? ParentColors.shell
            : Colors.white.withValues(alpha: 0.85),
        shape: StadiumBorder(
          side: BorderSide(color: ParentColors.shell, width: 2),
        ),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Text(
              label,
              style: GoogleFonts.onest(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : ParentColors.shell,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ColorLetterActionRow extends StatelessWidget {
  const ColorLetterActionRow({
    super.key,
    required this.clearDisabled,
    required this.doneDisabled,
    required this.onClear,
    required this.onDone,
  });

  final bool clearDisabled;
  final bool doneDisabled;
  final VoidCallback onClear;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        ColorLetterActionButton(
          disabled: clearDisabled,
          filled: false,
          label: 'Стереть',
          onPressed: onClear,
        ),
        ColorLetterActionButton(
          disabled: doneDisabled,
          filled: true,
          label: 'Готово',
          onPressed: onDone,
        ),
      ],
    );
  }
}
