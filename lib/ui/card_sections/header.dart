import 'package:flutter/material.dart';

import '../../api/models.dart';

class CardHeaderSection extends StatelessWidget {
  const CardHeaderSection({
    super.key,
    required this.card,
    required this.onRename,
    required this.onDescriptionChanged,
  });

  final PlankaCard card;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: ValueKey('title-${card.id}-${card.name}'),
          initialValue: card.name,
          style: Theme.of(context).textTheme.titleLarge,
          decoration: const InputDecoration(border: InputBorder.none),
          onFieldSubmitted: (v) {
            final name = v.trim();
            if (name.isNotEmpty && name != card.name) onRename(name);
          },
        ),
        TextFormField(
          key: ValueKey('desc-${card.id}'),
          initialValue: card.description ?? '',
          maxLines: null,
          minLines: 2,
          decoration: const InputDecoration(
            hintText: 'Add a description…',
            border: InputBorder.none,
          ),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          onFieldSubmitted: onDescriptionChanged,
        ),
      ],
    );
  }
}
