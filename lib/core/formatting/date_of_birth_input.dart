import 'package:flutter/services.dart';

const dateOfBirthMaxDigits = 8;

/// Masks digits as `DD.MM.YYYY` while typing (dots inserted automatically).
class DateOfBirthInputFormatter extends TextInputFormatter {
  const DateOfBirthInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > dateOfBirthMaxDigits) {
      return oldValue;
    }

    final formatted = formatDateOfBirthDigits(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String formatDateOfBirthDigits(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i == 2 || i == 4) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String isoDateToDisplay(String? iso) {
  if (iso == null || iso.isEmpty) {
    return '';
  }
  final date = DateTime.tryParse(iso.contains('T') ? iso : '${iso}T00:00:00');
  if (date == null) {
    return iso;
  }
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

bool isCompleteDisplayDateOfBirth(String display) {
  return displayDateToIso(display) != null;
}

String? displayDateToIso(String display) {
  final digits = display.replaceAll(RegExp(r'\D'), '');
  if (digits.length != dateOfBirthMaxDigits) {
    return null;
  }

  final day = int.parse(digits.substring(0, 2));
  final month = int.parse(digits.substring(2, 4));
  final year = int.parse(digits.substring(4, 8));
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  if (date.isAfter(DateTime.now())) {
    return null;
  }

  final monthStr = month.toString().padLeft(2, '0');
  final dayStr = day.toString().padLeft(2, '0');
  return '$year-$monthStr-$dayStr';
}

DateTime? parseDateOfBirthInput(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.contains('-') && !trimmed.contains('.')) {
    return DateTime.tryParse(trimmed.contains('T') ? trimmed : '${trimmed}T00:00:00');
  }
  final iso = displayDateToIso(trimmed);
  if (iso == null) {
    return null;
  }
  return DateTime.tryParse('${iso}T00:00:00');
}
