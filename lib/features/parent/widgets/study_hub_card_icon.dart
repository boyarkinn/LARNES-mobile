import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/theme/hub_card_appearance.dart';

/// Иконка hub-карточки (stroke SVG как web).
/// Эталон: platform/src/components/parent/study-hub-card-icon.tsx
class StudyHubCardIcon extends StatelessWidget {
  const StudyHubCardIcon({
    super.key,
    required this.kind,
    required this.color,
    this.size = ParentStudyHubCardMetrics.iconImageSize,
  });

  final HubCardIconKind kind;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SvgPicture.string(
        _svgForKind(kind),
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}

String _svgForKind(HubCardIconKind kind) {
  const xmlns = 'xmlns="http://www.w3.org/2000/svg"';
  final body = switch (kind) {
    HubCardIconKind.profile => '''
<circle cx="12" cy="8.5" r="3.25" stroke="currentColor" stroke-width="1.75" fill="none"/>
<path d="M5.5 19.5c0-3.037 2.686-5 6.5-5s6.5 1.963 6.5 5" stroke="currentColor" stroke-linecap="round" stroke-width="1.75" fill="none"/>
''',
    HubCardIconKind.homework => '''
<path d="M7 4.5h8.172a1 1 0 0 1 .707.293l2.328 2.328A1 1 0 0 1 18.5 7.828V19.5a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1v-15a1 1 0 0 1 1-1Z" stroke="currentColor" stroke-linejoin="round" stroke-width="1.75" fill="none"/>
<path d="M15 4.5V7a1 1 0 0 0 1 1h2.5M9 12h6M9 15.5h4" stroke="currentColor" stroke-linecap="round" stroke-width="1.75" fill="none"/>
''',
    HubCardIconKind.reading => '''
<path d="M5.5 6.5A2.5 2.5 0 0 1 8 4h9.5v15.5H8A2.5 2.5 0 0 0 5.5 22V6.5Z" stroke="currentColor" stroke-linejoin="round" stroke-width="1.75" fill="none"/>
<path d="M8 4a2.5 2.5 0 0 0-2.5 2.5V22A2.5 2.5 0 0 1 8 19.5h9.5" stroke="currentColor" stroke-linejoin="round" stroke-width="1.75" fill="none"/>
''',
    HubCardIconKind.writing => '''
<path d="m14.5 5.5 4 4M7 17.5 5 19l-1.5 3.5L7 21l1.5-3 9.879-9.879a1.5 1.5 0 0 0 0-2.121l-1.379-1.379a1.5 1.5 0 0 0-2.121 0L7 17.5Z" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.75" fill="none"/>
''',
    HubCardIconKind.math => '''
<path d="M8 7h8M8 12h8M8 17h5" stroke="currentColor" stroke-linecap="round" stroke-width="1.75" fill="none"/>
<rect x="4" y="4" width="16" height="16" rx="2" stroke="currentColor" stroke-width="1.75" fill="none"/>
''',
    HubCardIconKind.direction => '''
<path d="M12 4.5 5 8v8l7 3.5 7-3.5V8l-7-3.5Z" stroke="currentColor" stroke-linejoin="round" stroke-width="1.75" fill="none"/>
<path d="M12 12 5 8M12 12v7.5M12 12l7-4" stroke="currentColor" stroke-linejoin="round" stroke-width="1.75" fill="none"/>
''',
    HubCardIconKind.courses => '''
<path d="M5.5 8.5 12 5l6.5 3.5v7L12 19l-6.5-3.5v-7Z" stroke="currentColor" stroke-linejoin="round" stroke-width="1.75" fill="none"/>
<path d="M12 12v7M5.5 8.5 12 12l6.5-3.5" stroke="currentColor" stroke-linejoin="round" stroke-width="1.75" fill="none"/>
''',
    HubCardIconKind.attendance => '''
<path d="M8 4h8a2 2 0 0 1 2 2v13.5H6V6a2 2 0 0 1 2-2Z" stroke="currentColor" stroke-linejoin="round" stroke-width="1.75" fill="none"/>
<path d="M9 2.5V6M15 2.5V6M8 11h3M8 14.5h8" stroke="currentColor" stroke-linecap="round" stroke-width="1.75" fill="none"/>
''',
    HubCardIconKind.schedule => '''
<circle cx="12" cy="12" r="8.25" stroke="currentColor" stroke-width="1.75" fill="none"/>
<path d="M12 7.5V12l3 2" stroke="currentColor" stroke-linecap="round" stroke-width="1.75" fill="none"/>
''',
    HubCardIconKind.payments => '''
<rect x="4" y="7" width="16" height="11" rx="2" stroke="currentColor" stroke-width="1.75" fill="none"/>
<path d="M8 7V5.5A1.5 1.5 0 0 1 9.5 4h5A1.5 1.5 0 0 1 16 5.5V7M4 11h16" stroke="currentColor" stroke-linecap="round" stroke-width="1.75" fill="none"/>
''',
    HubCardIconKind.rewards => '''
<path d="M4.5 8.5h15v3.2a3.8 3.8 0 0 1-3.8 3.8H8.3A3.8 3.8 0 0 1 4.5 11.7V8.5Zm2-3.2h11l1.4 3.2H5.1L6.5 5.3ZM12 8.5v10" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.75" fill="none"/>
''',
  };

  return '<svg $xmlns viewBox="0 0 24 24" fill="none">$body</svg>';
}
