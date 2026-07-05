import 'package:flutter/material.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Read-only education blocks on child profile (web `ChildEducationProfile`).
List<Widget> childEducationProfileCards({
  required BuildContext context,
  required ParentChild child,
  required ChildEducationContext education,
}) {
  final l10n = context.l10n;
  final tokens = childCardColorTokens(child.cardColor);
  final cards = <Widget>[];

  if (!education.hasEducation) {
    cards.add(
      AccountDeskCard(
        bandTitle: l10n.parentChildEducationTitle,
        tokens: tokens,
        child: AccountEmptyText(text: l10n.parentChildEducationEmpty),
      ),
    );
    return cards;
  }

  if (education.tutors.isNotEmpty) {
    cards.add(
      AccountDeskCard(
        bandTitle: l10n.parentChildTutorSection,
        tokens: tokens,
        child: Column(
          children: [
            for (var tutorIndex = 0; tutorIndex < education.tutors.length; tutorIndex++) ...[
              if (tutorIndex > 0) const AccountDivider(),
              AccountInfoRow(
                label: l10n.parentChildTeacherLabel,
                value: education.tutors[tutorIndex].teacherName,
              ),
              const AccountDivider(),
              if (education.tutors[tutorIndex].groups.isNotEmpty)
                AccountInfoRow(
                  label: l10n.parentChildGroupsLabel,
                  value: education.tutors[tutorIndex].groups.map((g) => g.name).join(', '),
                )
              else
                AccountInfoRow(
                  label: l10n.parentChildGroupsLabel,
                  hint: l10n.parentChildTutorNoGroups,
                ),
            ],
          ],
        ),
      ),
    );
  }

  for (final network in education.networks) {
    cards.add(
      AccountDeskCard(
        bandTitle: l10n.parentChildNetworkSection(network.networkName),
        tokens: tokens,
        child: network.groups.isEmpty
            ? AccountEmptyText(text: l10n.parentChildNetworkNoGroups)
            : Column(
                children: [
                  for (var i = 0; i < network.groups.length; i++) ...[
                    if (i > 0) const AccountDivider(),
                    AccountInfoRow(
                      label: network.groups[i].groupName,
                      value: network.groups[i].centerLabel,
                    ),
                    const AccountDivider(),
                    AccountInfoRow(
                      label: l10n.parentChildTeacherLabel,
                      value: network.groups[i].teacherName ?? l10n.parentChildTeacherNotAssigned,
                      valueMuted: network.groups[i].teacherName == null,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  return cards;
}
