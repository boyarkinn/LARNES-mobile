import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Силуэт ребёнка по полу (кольцо карточки Morning Desk v4).
/// Эталон: platform/src/components/parent/child-gender-silhouette.tsx
class ChildGenderSilhouette extends StatelessWidget {
  const ChildGenderSilhouette({
    super.key,
    required this.gender,
    required this.color,
    this.size = 26,
  });

  final String gender;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (gender != 'male' && gender != 'female') {
      return SizedBox(width: size, height: size);
    }

    return ExcludeSemantics(
      child: SvgPicture.string(
        _svgForGender(gender),
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}

String _svgForGender(String gender) {
  const xmlns = 'xmlns="http://www.w3.org/2000/svg"';
  final body = gender == 'male'
      ? '''
<path d="M12 3c3.05 0 5.5 2.45 5.5 5.5 0 1.3-.45 2.5-1.2 3.45 1.65 1.15 2.7 3.05 2.7 5.3 0 2.65-2.85 4.25-7 4.25s-7-1.6-7-4.25c0-2.25 1.05-4.15 2.7-5.3-.75-.95-1.2-2.15-1.2-3.45C6.5 5.45 8.95 3 12 3Zm0 1.25c-.55 0-1.05.1-1.5.25.45.2.95.3 1.5.3s1.05-.1 1.5-.3c-.45-.15-.95-.25-1.5-.25Z" fill="currentColor"/>
'''
      : '''
<path d="M12 3.5c-2.95 0-5.35 2.4-5.35 5.35 0 1.25.42 2.4 1.12 3.28-1.54 1.12-2.52 2.93-2.52 4.97 0 2.52 2.68 4.15 6.75 4.15s6.75-1.63 6.75-4.15c0-2.04-.98-3.85-2.52-4.97.7-.88 1.12-2.03 1.12-3.28 0-2.95-2.4-5.35-5.35-5.35Z" fill="currentColor"/>
<ellipse cx="6.1" cy="9.8" rx="2.6" ry="3.1" fill="currentColor"/>
<ellipse cx="17.9" cy="9.8" rx="2.6" ry="3.1" fill="currentColor"/>
''';

  return '<svg $xmlns viewBox="0 0 24 24">$body</svg>';
}
