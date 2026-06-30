import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/utils/child_display.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';

class ChildProfileCard extends StatelessWidget {
  const ChildProfileCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  final ParentChild child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context).localeCode;
    final names = childDisplayNameLines(child);
    final age = child.ageYears;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: parentCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (names.lastName.isNotEmpty)
                Text(
                  names.lastName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: LarnesColors.textPrimary,
                  ),
                ),
              if (names.givenName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  names.givenName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: LarnesColors.textPrimary,
                  ),
                ),
              ],
              if (age != null) ...[
                const SizedBox(height: 10),
                Text(
                  formatChildAgeYears(age, locale),
                  style: const TextStyle(
                    fontSize: 14,
                    color: LarnesColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
