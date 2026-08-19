import 'package:flutter/material.dart';

/// Design tokens from `platform/src/app/themes/auth.css` + `public-surface-tokens.css`.
abstract final class AuthColors {
  static const bg = Color(0xFFF4F1EB);
  static const surface = Color(0xFFFFFDF9);
  static const surfaceStrong = Color(0xFFFFFFFF);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF596174);
  static const line = Color(0xFFD9D4CA);
  static const cobalt = Color(0xFF345BFF);
  static const cobaltDeep = Color(0xFF2448DC);
  static const cobaltSoft = Color(0xFFE4E9FF);
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFFF0ED);
  static const success = Color(0xFF147D52);
  static const capsHint = Color(0xFF8B5C00);
  static const placeholder = Color(0xFF9699A8);
  static const headerBg = Color(0xE6F5F7F2);
}

abstract final class AuthRadii {
  static const input = 14.0;
  static const button = 14.0;
  static const headerControl = 10.0;
}

abstract final class AuthMetrics {
  static const inputMinHeight = 50.0;
  static const buttonMinHeight = 50.0;
  static const formMaxWidth = 360.0;
  static const horizontalPadding = 20.0;
  static const headerMinHeight = 72.0;
  static const formGap = 14.0;
  static const ruledLineStep = 34.0;
}

abstract final class AuthMotion {
  static const duration = Duration(milliseconds: 160);
  static const tapDuration = Duration(milliseconds: 100);
  static const curve = Cubic(0.22, 1, 0.36, 1);
}
