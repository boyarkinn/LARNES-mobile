import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class KioskUnplacedScreen extends StatelessWidget {
  const KioskUnplacedScreen({super.key});

  static const _porcelain = Color(0xFFF5F7F2);
  static const _paper = Color(0xFFFFFEFA);
  static const _ink = Color(0xFF12262F);
  static const _muted = Color(0xFF62747A);
  static const _blue = Color(0xFF345BFF);
  static const _blueSoft = Color(0xFFE4E9FF);
  static const _green = Color(0xFF1D9B78);
  static const _line = Color(0xFFD8E0DC);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = [
      l10n.kioskUnplacedStep1,
      l10n.kioskUnplacedStep2,
      l10n.kioskUnplacedStep3,
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
                  l10n.kioskUnplacedEyebrow,
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
                  l10n.kioskUnplacedTitle,
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
                  l10n.kioskUnplacedSubtitle,
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _WaitingDot(reduceMotion: MediaQuery.disableAnimationsOf(context)),
                    const SizedBox(width: 8),
                    Text(
                      l10n.kioskUnplacedWaiting,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
            color: KioskUnplacedScreen._blueSoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: KioskUnplacedScreen._blue,
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
              color: KioskUnplacedScreen._ink,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _WaitingDot extends StatefulWidget {
  const _WaitingDot({required this.reduceMotion});

  final bool reduceMotion;

  @override
  State<_WaitingDot> createState() => _WaitingDotState();
}

class _WaitingDotState extends State<_WaitingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _opacity = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (!widget.reduceMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: widget.reduceMotion ? 0.85 : _opacity.value,
          child: Transform.scale(
            scale: widget.reduceMotion ? 1 : _scale.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: KioskUnplacedScreen._green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
