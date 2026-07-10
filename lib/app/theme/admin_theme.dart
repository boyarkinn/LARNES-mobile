import 'package:flutter/material.dart';

/// Neutral admin panel tokens (web admin gray + indigo).
class AdminColors {
  const AdminColors._();

  static const background = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF111827);
  static const inkMuted = Color(0xFF6B7280);
  static const line = Color(0xFFE5E7EB);
  static const accent = Color(0xFF4F46E5);
  static const accentDeep = Color(0xFF4338CA);
}

class AdminMotion {
  const AdminMotion._();

  static const tapDuration = Duration(milliseconds: 100);
  static const curve = Cubic(0.22, 1, 0.36, 1);
}
