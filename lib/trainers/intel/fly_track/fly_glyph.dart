import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Web: `FlyGlyph` in `platform/src/trainers/intel/fly-track/component.tsx`
class FlyGlyph extends StatelessWidget {
  const FlyGlyph({super.key, this.size});

  final double? size;

  static const _svg = '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="22" cy="22" fill="#99F6E4" rx="19" ry="10" transform="rotate(-28 22 22)" />
  <ellipse cx="42" cy="22" fill="#CCFBF1" rx="19" ry="10" transform="rotate(28 42 22)" />
  <ellipse cx="32" cy="40" fill="#134E4A" rx="9" ry="17" />
  <circle cx="32" cy="24" fill="#0F766E" r="9" />
  <path d="M26 18 18 8M38 18l8-10M25 49 14 57M39 49l11 8" stroke="#134E4A" stroke-linecap="round" stroke-width="3" fill="none" />
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSide = size ??
            [
              constraints.maxWidth * 0.7,
              constraints.maxHeight * 0.7,
              56.0,
            ].reduce((a, b) => a < b ? a : b);

        return SvgPicture.string(
          _svg,
          width: maxSide,
          height: maxSide,
          semanticsLabel: 'Муха',
        );
      },
    );
  }
}
