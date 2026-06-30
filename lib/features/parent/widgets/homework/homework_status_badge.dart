import 'package:flutter/material.dart';
import 'package:larnes_mobile/features/parent/utils/homework_display.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class HomeworkStatusBadge extends StatelessWidget {
  const HomeworkStatusBadge({super.key, required this.displayStatus});

  final String displayStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = _colorsForStatus(displayStatus);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          homeworkStatusLabel(l10n, displayStatus),
          style: TextStyle(
            color: colors.$2,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  (Color, Color) _colorsForStatus(String status) {
    switch (status) {
      case 'completed':
        return (const Color(0xFFDCFCE7), const Color(0xFF166534));
      case 'in_progress':
        return (const Color(0xFFDBEAFE), const Color(0xFF1E40AF));
      case 'overdue':
        return (const Color(0xFFFEE2E2), const Color(0xFFB91C1C));
      default:
        return (const Color(0xFFF3F4F6), const Color(0xFF374151));
    }
  }
}
