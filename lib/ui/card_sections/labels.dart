import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../widgets/card_tile.dart' show labelColor;

/// Planka's fixed label color names (create-label dialog palette).
const kPlankaLabelColorNames = [
  'berry-red', 'pumpkin-orange', 'lagoon-blue', 'pink-tulip', 'light-mud',
  'orange-peel', 'bright-moss', 'antique-blue', 'dark-granite',
  'turquoise-sea', 'sunny-grass', 'morning-sky', 'light-orange',
  'midnight-blue', 'tank-green', 'gun-metal', 'wet-moss', 'red-burgundy',
  'light-concrete', 'apricot-red', 'desert-sand', 'navy-blue', 'egg-yellow',
  'coral-green', 'light-cocoa',
];

class CardLabelsSection extends StatelessWidget {
  const CardLabelsSection({
    super.key,
    required this.boardLabels,
    required this.activeLabelIds,
    required this.onToggle,
    required this.onCreate,
  });

  final List<PlankaLabel> boardLabels;
  final Set<String> activeLabelIds;
  final ValueChanged<String> onToggle;
  final void Function(String name, String color) onCreate;

  Future<void> _createDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    var color = kPlankaLabelColorNames.first;
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in kPlankaLabelColorNames)
                    InkWell(
                      onTap: () => setState(() => color = c),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: labelColor(c),
                          borderRadius: BorderRadius.circular(6),
                          border: color == c
                              ? Border.all(width: 3, color: Theme.of(context).colorScheme.primary)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Create')),
          ],
        ),
      ),
    );
    if (created == true) onCreate(nameCtrl.text.trim(), color);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final l in boardLabels)
          FilterChip(
            label: Text(l.name?.isNotEmpty == true ? l.name! : l.color),
            selected: activeLabelIds.contains(l.id),
            backgroundColor: labelColor(l.color).withValues(alpha: 0.25),
            selectedColor: labelColor(l.color),
            onSelected: (_) => onToggle(l.id),
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('Label'),
          onPressed: () => _createDialog(context),
        ),
      ],
    );
  }
}
