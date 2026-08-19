import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';

void main() {
  test('AuthColors match web auth.css tokens', () {
    expect(AuthColors.bg, const Color(0xFFF4F1EB));
    expect(AuthColors.cobalt, const Color(0xFF345BFF));
    expect(AuthColors.cobaltDeep, const Color(0xFF2448DC));
    expect(AuthColors.ink, const Color(0xFF172033));
  });
}
