/// Каталог slug персонажей-аватаров ребёнка.
/// Эталон: platform/src/server/parent/child-avatar-catalog.ts
enum ChildAvatarSlug {
  fox,
  bear,
  owl,
}

const childAvatarSlugs = ChildAvatarSlug.values;

const defaultChildAvatarSlug = ChildAvatarSlug.fox;

ChildAvatarSlug? parseChildAvatarSlug(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  for (final slug in ChildAvatarSlug.values) {
    if (slug.name == value) {
      return slug;
    }
  }
  return null;
}

ChildAvatarSlug childAvatarSlugFromString(String? value) {
  return parseChildAvatarSlug(value) ?? defaultChildAvatarSlug;
}
