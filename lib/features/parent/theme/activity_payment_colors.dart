import 'package:flutter/material.dart';

/// Shared payment-tone palette for parent activity calendar + schedule.
class ActivityPaymentSurfaceColors {
  const ActivityPaymentSurfaceColors({
    required this.background,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
  });

  final Color background;
  final Color border;
  final Color primaryText;
  final Color secondaryText;
}

ActivityPaymentSurfaceColors activityPaymentSurfaceColors(String tone) {
  return switch (tone) {
    'paid' || 'gift' || 'carryover' => const ActivityPaymentSurfaceColors(
      background: Color(0xFF4ADE80),
      border: Color(0x2E15832D),
      primaryText: Color(0xFF14532D),
      secondaryText: Color(0x9E14532D),
    ),
    'first-unpaid' => const ActivityPaymentSurfaceColors(
      background: Color(0xFFEF4444),
      border: Color(0x387F1D1D),
      primaryText: Colors.white,
      secondaryText: Color(0xC7FFFFFF),
    ),
    'unpaid' => const ActivityPaymentSurfaceColors(
      background: Color(0xFF9CA3AF),
      border: Color(0x38374151),
      primaryText: Colors.white,
      secondaryText: Color(0xC7FFFFFF),
    ),
    'makeup' => const ActivityPaymentSurfaceColors(
      background: Color(0xFF67E8F9),
      border: Color(0x33155E75),
      primaryText: Color(0xFF155E75),
      secondaryText: Color(0x99155E75),
    ),
    'other-group' => const ActivityPaymentSurfaceColors(
      background: Color(0xFFFFFFFF),
      border: Color(0xFFE5E7EB),
      primaryText: Color(0xFF4A5068),
      secondaryText: Color(0xFF4A5068),
    ),
    _ => const ActivityPaymentSurfaceColors(
      background: Color(0xFFFFFFFF),
      border: Color(0xFFE5E7EB),
      primaryText: Color(0xFF1A1D2E),
      secondaryText: Color(0xFF4A5068),
    ),
  };
}

const activityPaymentLegendPaid = Color(0xFF4ADE80);
const activityPaymentLegendFirstUnpaid = Color(0xFFEF4444);
const activityPaymentLegendUnpaid = Color(0xFF9CA3AF);
const activityPaymentLegendMakeup = Color(0xFF67E8F9);
