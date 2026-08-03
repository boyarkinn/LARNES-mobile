import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';

/// Иконки hub-карточек parent (Morning Desk v4).
enum HubCardIconKind {
  profile,
  homework,
  reading,
  writing,
  math,
  direction,
  courses,
  attendance,
  schedule,
  payments,
}

enum ActivityHubKind {
  attendance,
  schedule,
  payments,
}

/// Эталон: platform/src/server/parent/hub-card-appearance.ts
const profileHubCardTokens = ChildCardColorTokens(
  tag: ParentColors.shell,
  tagDeep: ParentColors.shellDeep,
  soft: ParentColors.shellSoft,
);

ChildCardColorTokens homeworkHubCardTokens() {
  return childCardColorTokens(ChildCardColor.orange);
}

ChildCardColorTokens coursesHubCardTokens() {
  return childCardColorTokens(ChildCardColor.violet);
}

ChildCardColorTokens activityHubCardTokens(ActivityHubKind kind) {
  return switch (kind) {
    ActivityHubKind.attendance => childCardColorTokens(ChildCardColor.emerald),
    ActivityHubKind.schedule => profileHubCardTokens,
    ActivityHubKind.payments => childCardColorTokens(ChildCardColor.orange),
  };
}

HubCardIconKind activityHubIconKind(ActivityHubKind kind) {
  return switch (kind) {
    ActivityHubKind.attendance => HubCardIconKind.attendance,
    ActivityHubKind.schedule => HubCardIconKind.schedule,
    ActivityHubKind.payments => HubCardIconKind.payments,
  };
}

const _directionSlugColor = <String, ChildCardColor>{
  'chtenie': ChildCardColor.sky,
  'reading': ChildCardColor.sky,
  'pismo': ChildCardColor.violet,
  'writing': ChildCardColor.violet,
  'math': ChildCardColor.emerald,
  'matematika': ChildCardColor.emerald,
  'arifmetika-i-matematika': ChildCardColor.emerald,
};

bool _slugMatches(String slug, String fragment) {
  return slug.contains(fragment);
}

ChildCardColor resolveDirectionHubCardColor(String directionSlug, {int sortOrder = 0}) {
  final slug = directionSlug.trim().toLowerCase();

  final mapped = _directionSlugColor[slug];
  if (mapped != null) {
    return mapped;
  }

  if (_slugMatches(slug, 'chten') || _slugMatches(slug, 'read')) {
    return ChildCardColor.sky;
  }

  if (_slugMatches(slug, 'pism') || _slugMatches(slug, 'writ')) {
    return ChildCardColor.violet;
  }

  if (_slugMatches(slug, 'math') || _slugMatches(slug, 'matem') || _slugMatches(slug, 'arifm')) {
    return ChildCardColor.emerald;
  }

  final index = sortOrder.abs() % childCardColors.length;
  return childCardColors[index];
}

ChildCardColorTokens directionHubCardTokens(String directionSlug, {int sortOrder = 0}) {
  return childCardColorTokens(resolveDirectionHubCardColor(directionSlug, sortOrder: sortOrder));
}

/// Эталон: platform/src/server/homework/homework-card-appearance.ts
ChildCardColorTokens homeworkAssignmentCardTokens(String displayStatus) {
  switch (displayStatus) {
    case 'overdue':
      return childCardColorTokens(ChildCardColor.rose);
    case 'completed':
      return childCardColorTokens(ChildCardColor.emerald);
    case 'in_progress':
      return profileHubCardTokens;
    case 'assigned':
    default:
      return childCardColorTokens(ChildCardColor.sky);
  }
}

HubCardIconKind resolveDirectionHubIconKind(String directionSlug) {
  final slug = directionSlug.trim().toLowerCase();

  if (_slugMatches(slug, 'chten') || _slugMatches(slug, 'read') || slug == 'reading') {
    return HubCardIconKind.reading;
  }

  if (_slugMatches(slug, 'pism') || _slugMatches(slug, 'writ') || slug == 'writing') {
    return HubCardIconKind.writing;
  }

  if (_slugMatches(slug, 'math') || _slugMatches(slug, 'matem') || _slugMatches(slug, 'arifm')) {
    return HubCardIconKind.math;
  }

  return HubCardIconKind.direction;
}
