import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class KioskRegistrationScreen extends StatelessWidget {
  const KioskRegistrationScreen({super.key});

  static const _porcelain = Color(0xFFF5F7F2);
  static const _paper = Color(0xFFFFFEFA);
  static const _ink = Color(0xFF12262F);
  static const _muted = Color(0xFF62747A);
  static const _blue = Color(0xFF345BFF);
  static const _blueSoft = Color(0xFFE4E9FF);
  static const _line = Color(0xFFD8E0DC);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = [
      l10n.kioskRegistrationStep1,
      l10n.kioskRegistrationStep2,
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0x1A345BFF),
            _porcelain,
            Color(0x141D9B78),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
        color: _porcelain,
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/brand/mark-blue.svg',
                  width: 56,
                  height: 56,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.kioskRegistrationEyebrow,
                  style: const TextStyle(
                    color: _blue,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.kioskRegistrationTitle,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.kioskRegistrationSubtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _paper,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _line),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1C12262F),
                        blurRadius: 40,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                    child: Column(
                      children: [
                        for (var index = 0; index < steps.length; index++) ...[
                          if (index > 0) const SizedBox(height: 14),
                          _StepRow(
                            index: index + 1,
                            text: steps[index],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    onPressed: () => context.go(kioskLoginRedirect),
                    child: Text(l10n.kioskRegistrationSignIn),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.text,
  });

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: KioskRegistrationScreen._blueSoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: KioskRegistrationScreen._blue,
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: KioskRegistrationScreen._ink,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
