import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';

class MessengerBubbleSurface extends StatelessWidget {
  const MessengerBubbleSurface({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 8),
  });
  final Widget child;
  final EdgeInsetsGeometry margin;
  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: ParentColors.parchment,
      borderRadius: BorderRadius.circular(8),
    ),
    child: child,
  );
}
