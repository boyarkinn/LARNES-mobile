import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_text_theme.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_sub_bar.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_top_bar.dart';

/// Page chrome inside [ParentShellScaffold] — header, optional sub-bar, body.
class ParentScaffold extends StatelessWidget {
  const ParentScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBack,
    this.subBar,
  });

  final String title;
  final Widget body;

  /// When null, back chevron follows [GoRouter.canPop] on the current branch.
  final bool? showBack;

  /// Optional strip under the header (e.g. homework filter tabs).
  final Widget? subBar;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(textTheme: buildParentTextTheme()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ParentHeader(title: title, showBack: showBack),
          if (subBar != null) ParentSubBar(child: subBar!),
          Expanded(child: body),
        ],
      ),
    );
  }
}
