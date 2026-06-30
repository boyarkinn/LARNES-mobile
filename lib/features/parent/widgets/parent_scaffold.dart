import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';
import 'package:larnes_mobile/features/auth/widgets/language_switcher.dart';

class ParentScaffold extends StatelessWidget {
  const ParentScaffold({
    super.key,
    required this.title,
    required this.body,
    this.accountLabel,
    this.onAccount,
    this.backLabel,
    this.onBack,
  });

  final String title;
  final Widget body;
  final String? accountLabel;
  final VoidCallback? onAccount;
  final String? backLabel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: LarnesColors.skyBottom),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: LarnesColors.border),
          ),
          leading: onBack != null
              ? TextButton(
                  onPressed: onBack,
                  child: Text(
                    backLabel ?? '',
                    style: const TextStyle(
                      color: LarnesColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : null,
          leadingWidth: onBack != null ? 96 : null,
          title: Text(
            title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              color: LarnesColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        actions: [
          if (accountLabel != null && onAccount != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: OutlinedButton(
                onPressed: onAccount,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  side: const BorderSide(color: LarnesColors.border),
                  foregroundColor: LarnesColors.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  accountLabel!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          const LanguageSwitcher(),
          const SizedBox(width: 8),
        ],
        ),
        body: SafeArea(top: false, child: body),
      ),
    );
  }
}

BoxDecoration parentCardDecoration({bool dashed = false}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: LarnesColors.border,
      strokeAlign: BorderSide.strokeAlignInside,
    ),
  );
}
