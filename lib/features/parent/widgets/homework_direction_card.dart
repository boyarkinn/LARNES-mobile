import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';

class HomeworkDirectionCard extends StatelessWidget {
  const HomeworkDirectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: onTap == null
          ? Ink(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: parentCardDecoration(),
              child: _content(),
            )
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: parentCardDecoration(),
                child: _content(),
              ),
            ),
    );
  }

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: LarnesColors.textPrimary,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: LarnesColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
