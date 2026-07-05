import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:larnes_mobile/features/parent/theme/child_avatar_catalog.dart';

/// Эталон: platform/src/components/parent/child-avatar.tsx
const childAvatarAssetPaths = <ChildAvatarSlug, String>{
  ChildAvatarSlug.fox: 'assets/parent/avatars/child_avatar_fox.svg',
  ChildAvatarSlug.bear: 'assets/parent/avatars/child_avatar_bear.svg',
  ChildAvatarSlug.owl: 'assets/parent/avatars/child_avatar_owl.svg',
};

ChildAvatarSlug resolveChildAvatarSlug(String slug) {
  return childAvatarSlugFromString(slug);
}

/// Персонаж-аватар ребёнка по slug из каталога.
class ChildAvatar extends StatelessWidget {
  const ChildAvatar({
    super.key,
    required this.slug,
    this.size = 40,
  });

  /// Принимает строковый slug из API; неизвестный → fox.
  ChildAvatar.fromString({
    super.key,
    required String slug,
    this.size = 40,
  }) : slug = resolveChildAvatarSlug(slug);

  final ChildAvatarSlug slug;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = childAvatarAssetPaths[slug]!;

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          assetPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
