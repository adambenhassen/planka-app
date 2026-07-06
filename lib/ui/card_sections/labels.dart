import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../widgets/label_colors.dart';

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
    var color = kLabelColorNames.first;
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
                  for (final c in kLabelColorNames)
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
    nameCtrl.dispose();
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
