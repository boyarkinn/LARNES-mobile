import 'package:flutter/material.dart';

/// Каталог «любимых цветов» карточки ребёнка (Morning Desk v4).
/// Эталон: platform/src/server/parent/child-card-colors.ts
enum ChildCardColor {
  orange,
  emerald,
  violet,
  sky,
  rose,
  amber,
}

const childCardColors = ChildCardColor.values;

const defaultChildCardColor = ChildCardColor.orange;

class ChildCardColorTokens {
  const ChildCardColorTokens({
    required this.tag,
    required this.tagDeep,
    required this.soft,
  });

  final Color tag;
  final Color tagDeep;
  final Color soft;
}

const _tokens = <ChildCardColor, ChildCardColorTokens>{
  ChildCardColor.orange: ChildCardColorTokens(
    tag: Color(0xFFFF6B35),
    tagDeep: Color(0xFFE04F1A),
    soft: Color(0xFFFFF0E8),
  ),
  ChildCardColor.emerald: ChildCardColorTokens(
    tag: Color(0xFF1B8A6B),
    tagDeep: Color(0xFF126B52),
    soft: Color(0xFFE3F5EF),
  ),
  ChildCardColor.violet: ChildCardColorTokens(
    tag: Color(0xFF6B4EAA),
    tagDeep: Color(0xFF523A88),
    soft: Color(0xFFF0EBFA),
  ),
  ChildCardColor.sky: ChildCardColorTokens(
    tag: Color(0xFF0C8BD6),
    tagDeep: Color(0xFF07689F),
    soft: Color(0xFFE3F2FC),
  ),
  ChildCardColor.rose: ChildCardColorTokens(
    tag: Color(0xFFE84855),
    tagDeep: Color(0xFFC91D38),
    soft: Color(0xFFFFE8EA),
  ),
  ChildCardColor.amber: ChildCardColorTokens(
    tag: Color(0xFFF2A022),
    tagDeep: Color(0xFFC97704),
    soft: Color(0xFFFFF4E0),
  ),
};

ChildCardColor? parseChildCardColor(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  for (final color in ChildCardColor.values) {
    if (color.name == value) {
      return color;
    }
  }
  return null;
}

ChildCardColor childCardColorFromString(String? value) {
  return parseChildCardColor(value) ?? defaultChildCardColor;
}

ChildCardColorTokens childCardColorTokens(ChildCardColor slug) {
  return _tokens[slug]!;
}

ChildCardColorTokens childCardColorTokensFromSlug(String? slug) {
  return childCardColorTokens(parseChildCardColor(slug) ?? defaultChildCardColor);
}
