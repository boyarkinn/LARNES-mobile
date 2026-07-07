import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';

/// Morning Desk text field — shared by auth flows and parent account forms.
class DeskTextField extends StatelessWidget {
  const DeskTextField({
    super.key,
    required this.controller,
    required this.label,
    this.labelAsPlaceholder = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.readOnly = false,
    this.onTap,
    this.hintText,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool labelAsPlaceholder;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  static const fieldRadius = 10.0;

  static InputDecoration inputDecoration({
    String? hintText,
    bool readOnly = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: const BorderSide(color: ParentColors.line),
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ParentColors.inkMuted,
      ),
      filled: true,
      fillColor: readOnly ? ParentColors.parchmentDeep.withValues(alpha: 0.35) : ParentColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: ParentColors.shell, width: 1),
      ),
      errorBorder: border,
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }

  static InputDecoration authInputDecoration({
    String? hintText,
    bool readOnly = false,
  }) =>
      inputDecoration(hintText: hintText, readOnly: readOnly);

  @override
  Widget build(BuildContext context) {
    final placeholder = hintText ?? label;

    final field = Semantics(
      label: label,
      textField: true,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        readOnly: readOnly,
        onTap: onTap,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: GoogleFonts.onest(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ParentColors.ink,
        ),
        decoration: inputDecoration(
          hintText: labelAsPlaceholder ? placeholder : hintText,
          readOnly: readOnly,
        ),
      ),
    );

    if (labelAsPlaceholder) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.onest(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ParentColors.inkMuted,
          ),
        ),
        const SizedBox(height: 4),
        field,
      ],
    );
  }
}
