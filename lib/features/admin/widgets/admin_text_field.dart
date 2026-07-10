import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';

class AdminTextField extends StatelessWidget {
  const AdminTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  static const fieldRadius = 8.0;

  static InputDecoration inputDecoration({bool readOnly = false}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: const BorderSide(color: AdminColors.line),
    );

    return InputDecoration(
      filled: true,
      fillColor: readOnly ? AdminColors.background : AdminColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: AdminColors.accent, width: 1),
      ),
      errorBorder: border,
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AdminColors.inkMuted,
          ),
        ),
        const SizedBox(height: 4),
        Semantics(
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
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AdminColors.ink,
            ),
            decoration: inputDecoration(readOnly: readOnly),
          ),
        ),
      ],
    );
  }
}
