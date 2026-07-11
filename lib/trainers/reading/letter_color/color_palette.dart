import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/letter_color_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';

/// Web: `platform/src/trainers/reading/letter-color/color-palette.tsx`
class ColorPalette extends StatelessWidget {
  const ColorPalette({
    super.key,
    required this.selectedColor,
    required this.onSelect,
    this.disabled = false,
  });

  final String selectedColor;
  final ValueChanged<String> onSelect;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final color in drawColors)
          _ColorSwatch(
            color: color,
            disabled: disabled,
            isSelected: selectedColor == color,
            onTap: () => onSelect(color),
          ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.disabled,
    required this.isSelected,
    required this.onTap,
  });

  final String color;
  final bool disabled;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = letterDisplayColorFromHex(color);

    return Semantics(
      button: true,
      label: 'Выбрать цвет',
      child: Material(
        color: fill,
        shape: CircleBorder(
          side: BorderSide(
            color: isSelected ? const Color(0xFF334155) : Colors.white.withValues(alpha: 0.9),
            width: 2,
          ),
        ),
        elevation: isSelected ? 4 : 1,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: disabled ? null : onTap,
          customBorder: const CircleBorder(),
          child: AnimatedScale(
            scale: isSelected ? 1.1 : 1,
            duration: const Duration(milliseconds: 150),
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      ),
    );
  }
}
