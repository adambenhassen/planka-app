import 'package:flutter/material.dart';

import '../../api/models.dart';

/// Blank stand-in for a field nobody has set a value for. The web client
/// renders the value line as a bare U+00A0 — the field name still shows, the
/// value is empty, with no placeholder text and no dash.
const String kEmptyCustomFieldValue = ' ';

/// One custom field group's fields and this card's values, read-only.
class CardCustomFieldsSection extends StatelessWidget {
  const CardCustomFieldsSection({super.key, required this.entries});

  /// The group's fields in position order, each with the card's value or null.
  final List<(PlankaCustomField, PlankaCustomFieldValue?)> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (field, value) in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.name,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Text(value?.content ?? kEmptyCustomFieldValue,
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
      ],
    );
  }
}
