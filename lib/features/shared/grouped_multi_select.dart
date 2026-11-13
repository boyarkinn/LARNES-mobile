import 'package:flutter/material.dart';

class GroupedSelectOption {
  const GroupedSelectOption({
    required this.value,
    required this.label,
    this.group = '',
  });
  final String value, label, group;
}

/// Shared searched/grouped picker for warm-up topics and content-bank subtopics.
Future<({List<String> selected, List<String> enabled})?>
showGroupedMultiSelect({
  required BuildContext context,
  required List<GroupedSelectOption> options,
  required List<String> selected,
  List<String> enabled = const [],
  required String title,
  required String searchLabel,
  required String allLabel,
  required String clearLabel,
  String? optionToggleLabel,
}) {
  final pending = selected.toSet(), switched = enabled.toSet();
  var query = '';
  return showDialog<({List<String> selected, List<String> enabled})>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, update) {
        final visible = options
            .where(
              (option) => '${option.label} ${option.group}'
                  .toLowerCase()
                  .replaceAll('ё', 'е')
                  .contains(query.trim().toLowerCase().replaceAll('ё', 'е')),
            )
            .toList();
        final groups = <String, List<GroupedSelectOption>>{};
        for (final option in visible) {
          groups.putIfAbsent(option.group, () => []).add(option);
        }
        void toggle(List<GroupedSelectOption> entries, bool checked) =>
            update(() {
              for (final option in entries) {
                if (checked) {
                  if (pending.add(option.value)) switched.add(option.value);
                } else {
                  pending.remove(option.value);
                  switched.remove(option.value);
                }
              }
            });
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 520,
            height: MediaQuery.sizeOf(context).height * .6,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(labelText: searchLabel),
                  onChanged: (value) => update(() => query = value),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => toggle(visible, true),
                        child: Text(allLabel),
                      ),
                    ),
                    TextButton(
                      onPressed: () => toggle(visible, false),
                      child: Text(clearLabel),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final group in groups.entries) ...[
                        if (group.key.isNotEmpty)
                          CheckboxListTile(
                            title: Text(group.key),
                            controlAffinity: ListTileControlAffinity.leading,
                            tristate: true,
                            value:
                                group.value.every(
                                  (option) => pending.contains(option.value),
                                )
                                ? true
                                : group.value.any(
                                    (option) => pending.contains(option.value),
                                  )
                                ? null
                                : false,
                            onChanged: (_) => toggle(
                              group.value,
                              !group.value.every(
                                (option) => pending.contains(option.value),
                              ),
                            ),
                          ),
                        for (final option in group.value)
                          Row(
                            children: [
                              Expanded(
                                child: CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(option.label),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  value: pending.contains(option.value),
                                  onChanged: (checked) =>
                                      toggle([option], checked == true),
                                ),
                              ),
                              if (optionToggleLabel != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      optionToggleLabel,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    Semantics(
                                      label:
                                          '$optionToggleLabel: ${option.label}',
                                      child: Switch(
                                        value:
                                            pending.contains(option.value) &&
                                            switched.contains(option.value),
                                        onChanged:
                                            !pending.contains(option.value)
                                            ? null
                                            : (checked) => update(() {
                                                checked
                                                    ? switched.add(option.value)
                                                    : switched.remove(
                                                        option.value,
                                                      );
                                              }),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, (
                selected: options
                    .where((option) => pending.contains(option.value))
                    .map((option) => option.value)
                    .toList(),
                enabled: options
                    .where(
                      (option) =>
                          pending.contains(option.value) &&
                          switched.contains(option.value),
                    )
                    .map((option) => option.value)
                    .toList(),
              )),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        );
      },
    ),
  );
}
