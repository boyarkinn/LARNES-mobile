import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/widgets/child_profile_appearance_fields.dart';

/// Child-runtime «привязан к планшету» — parity web `KioskChildBoundScreen`.
class KioskChildBoundView extends StatelessWidget {
  const KioskChildBoundView({
    super.key,
    required this.result,
  });

  final KioskScanResult result;

  @override
  Widget build(BuildContext context) {
    final tokens = childCardColorTokens(result.childCardColor);
    final lastName = result.childLastName ?? '';
    final givenName = result.childGivenName ?? result.childDisplayName;
    final nameStyle = GoogleFonts.fredoka(
      fontSize: 34,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.02 * 34,
      height: 1.08,
      color: const Color(0xFF1F2937),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tokens.soft,
            const Color(0xFFFFFEFA),
          ],
          stops: const [0, 0.58],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 352),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEFA),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.92), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: tokens.tagDeep.withValues(alpha: 0.18),
                    blurRadius: 64,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(29)),
                      gradient: LinearGradient(
                        colors: [tokens.tag, Color.lerp(tokens.tag, Colors.white, 0.28)!],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ChildCardColorRing(
                    tokens: tokens,
                    gender: result.childGender,
                    size: 120,
                  ),
                  const SizedBox(height: 18),
                  if (lastName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(lastName, style: nameStyle, textAlign: TextAlign.center),
                    ),
                  if (givenName.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, lastName.isNotEmpty ? 4 : 0, 20, 24),
                      child: Text(givenName, style: nameStyle, textAlign: TextAlign.center),
                    )
                  else
                    const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
