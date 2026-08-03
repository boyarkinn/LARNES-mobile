import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Place dock для parent activity — web `ParentActivityPlaceDock`.
class ParentActivityPlaceDock extends StatelessWidget {
  const ParentActivityPlaceDock({
    super.key,
    required this.places,
    required this.activePlaceId,
    required this.onPlaceSelected,
  });

  final List<ParentActivityPlace> places;
  final String activePlaceId;
  final ValueChanged<String> onPlaceSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Semantics(
      label: l10n.parentActivityPlaceDockLabel,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < places.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _PlaceChip(
                label: _placeLabel(l10n, places[i]),
                active: activePlaceId == places[i].placeId,
                archived: places[i].archived,
                onTap: () => onPlaceSelected(places[i].placeId),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _placeLabel(AppLocalizations l10n, ParentActivityPlace place) {
    if (place.placeId == parentActivitySummaryPlaceId ||
        place.kind == ParentActivityPlaceKind.summary) {
      return l10n.parentActivityPlaceSummary;
    }

    return place.label;
  }
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip({
    required this.label,
    required this.active,
    required this.archived,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool archived;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = archived && !active;

    return Opacity(
      opacity: archived && !active ? 0.65 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: active ? ParentColors.shell : ParentColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active ? ParentColors.shell : ParentColors.line,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active
                    ? Colors.white
                    : (muted ? ParentColors.inkMuted.withValues(alpha: 0.72) : ParentColors.inkMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
