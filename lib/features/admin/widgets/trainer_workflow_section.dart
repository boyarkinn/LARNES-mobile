import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';

class TrainerWorkflowAttachmentImage extends StatelessWidget {
  const TrainerWorkflowAttachmentImage({
    super.key,
    required this.dataUrl,
    this.height = 96,
  });

  final String dataUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final commaIndex = dataUrl.indexOf(',');

    if (commaIndex < 0) {
      return const SizedBox.shrink();
    }

    try {
      final bytes = base64Decode(dataUrl.substring(commaIndex + 1));

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

class TrainerWorkflowSection extends StatelessWidget {
  const TrainerWorkflowSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AdminColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
