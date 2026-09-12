import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Web: `FlyGlyph` in `platform/src/trainers/intel/fly-track/component.tsx`
class FlyGlyph extends StatefulWidget {
  const FlyGlyph({super.key, this.size});

  final double? size;

  @override
  State<FlyGlyph> createState() => _FlyGlyphState();
}

class _FlyGlyphState extends State<FlyGlyph>
    with SingleTickerProviderStateMixin {
  static const _leftWing = '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="22" cy="22" fill="#F8D98C" rx="19" ry="10" transform="rotate(-28 22 22)" />
</svg>
''';
  static const _rightWing = '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="42" cy="22" fill="#FFF0BE" rx="19" ry="10" transform="rotate(28 42 22)" />
</svg>
''';
  static const _body = '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="32" cy="40" fill="#173B73" rx="9" ry="17" />
  <circle cx="32" cy="24" fill="#2F66D0" r="9" />
  <path d="M26 18 18 8M38 18l8-10M25 49 14 57M39 49l11 8" stroke="#173B73" stroke-linecap="round" stroke-width="3" fill="none" />
</svg>
''';

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSide =
            widget.size ??
            [
              constraints.maxWidth * 0.7,
              constraints.maxHeight * 0.7,
              56.0,
            ].reduce((a, b) => a < b ? a : b);

        final reduceMotion = MediaQuery.disableAnimationsOf(context);

        return Semantics(
          label: 'Муха',
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = reduceMotion ? 0.0 : _controller.value;
              return Transform.translate(
                offset: Offset(0, -1.5 * progress),
                child: SizedBox(
                  width: maxSide,
                  height: maxSide,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Transform.rotate(
                        angle: -0.12 * progress,
                        alignment: const Alignment(0, -0.2),
                        child: SvgPicture.string(_leftWing),
                      ),
                      Transform.rotate(
                        angle: 0.12 * progress,
                        alignment: const Alignment(0, -0.2),
                        child: SvgPicture.string(_rightWing),
                      ),
                      SvgPicture.string(_body),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
