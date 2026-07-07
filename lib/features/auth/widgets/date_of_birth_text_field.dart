import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/formatting/date_of_birth_input.dart';
import 'package:larnes_mobile/features/parent/widgets/account/desk_text_field.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class DateOfBirthTextField extends StatelessWidget {
  const DateOfBirthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.textInputAction,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DeskTextField(
      controller: controller,
      label: label,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      inputFormatters: const [DateOfBirthInputFormatter()],
      hintText: context.l10n.dateOfBirthPlaceholder,
      onChanged: onChanged,
    );
  }
}
