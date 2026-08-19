import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';

class AuthStepper extends StatelessWidget {
  const AuthStepper({
    super.key,
    required this.current,
    required this.labels,
  });

  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(
              child: _AuthStep(
                index: index + 1,
                label: labels[index],
                isActive: current == index + 1,
                isComplete: current > index + 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthStep extends StatelessWidget {
  const _AuthStep({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isComplete,
  });

  final int index;
  final String label;
  final bool isActive;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final markerColor = isActive
        ? AuthColors.cobalt
        : isComplete
            ? AuthColors.cobaltSoft
            : AuthColors.cobaltSoft;
    final markerBorder = isActive
        ? AuthColors.cobalt
        : const Color.fromRGBO(52, 91, 255, 0.2);
    final markerTextColor = isActive ? Colors.white : AuthColors.cobaltDeep;
    final labelColor = isActive || isComplete
        ? AuthColors.cobaltDeep
        : const Color(0xFF838696);

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: markerColor,
            border: Border.all(color: markerBorder),
          ),
          child: Text(
            '$index',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: markerTextColor,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ),
      ],
    );
  }
}
