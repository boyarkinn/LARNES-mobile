import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';

/// Sticky strip under [ParentHeader] — web `.parent-sub-bar`.
class ParentSubBar extends StatelessWidget {
  const ParentSubBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ParentColors.surface.withValues(alpha: 0.88),
            border: const Border(bottom: BorderSide(color: ParentColors.line)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 7, 20, 7),
            child: SizedBox(
              width: double.infinity,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
