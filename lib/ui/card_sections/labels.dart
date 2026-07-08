import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/label_colors.dart';
import '../widgets/prompt_dialog.dart';

class CardLabelsSection extends StatelessWidget {
  const CardLabelsSection({
    super.key,
    required this.boardLabels,
    required this.activeLabelIds,
    required this.onToggle,
    required this.onCreate,
    required this.onEditLabel,
    required this.onDeleteLabel,
  });

  final List<PlankaLabel> boardLabels;
  final Set<String> activeLabelIds;
  final ValueChanged<String> onToggle;
  final void Function(String name, String color) onCreate;
  final void Function(String labelId, String name) onEditLabel;
  final ValueChanged<String> onDeleteLabel;

  Widget _swatch(String color) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      color: labelColor(color),
      borderRadius: BorderRadius.circular(6),
    ),
  );

  /// Board-level label management: lists every label with edit/delete and a
  /// field to create a new one. A local working copy keeps rows in sync as the
  /// user edits/deletes without closing the dialog.
  Future<void> _manageDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ManageLabelsDialog(
        boardLabels: boardLabels,
        onCreate: onCreate,
        onEditLabel: onEditLabel,
        onDeleteLabel: onDeleteLabel,
        swatchBuilder: _swatch,
      ),
    );
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
          onPressed: () => _manageDialog(context),
        ),
      ],
    );
  }
}

class _ManageLabelsDialog extends StatefulWidget {
  const _ManageLabelsDialog({
    required this.boardLabels,
    required this.onCreate,
    required this.onEditLabel,
    required this.onDeleteLabel,
    required this.swatchBuilder,
  });

  final List<PlankaLabel> boardLabels;
  final void Function(String name, String color) onCreate;
  final void Function(String labelId, String name) onEditLabel;
  final ValueChanged<String> onDeleteLabel;
  final Widget Function(String color) swatchBuilder;

  @override
  State<_ManageLabelsDialog> createState() => _ManageLabelsDialogState();
}

class _ManageLabelsDialogState extends State<_ManageLabelsDialog> {
  final TextEditingController _nameCtrl = TextEditingController();
  late final List<PlankaLabel> _labels = [...widget.boardLabels];
  String _color = kLabelColorNames.first;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _onAction(PlankaLabel label, String action) async {
    if (action == 'edit') {
      final name = await promptText(
        context,
        title: 'Rename label',
        initialValue: label.name ?? '',
      );
      if (!mounted || name == null) return;
      widget.onEditLabel(label.id, name);
      setState(() {
        final i = _labels.indexWhere((x) => x.id == label.id);
        if (i >= 0) {
          _labels[i] = PlankaLabel.fromJson({...label.toJson(), 'name': name});
        }
      });
    } else if (action == 'delete') {
      final ok = await confirmDialog(
        context,
        title: 'Delete label?',
        message: 'The label is removed from the board and all cards.',
        confirmLabel: 'Delete',
      );
      if (!mounted || !ok) return;
      widget.onDeleteLabel(label.id);
      setState(() => _labels.removeWhere((x) => x.id == label.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Labels'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in _labels)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: widget.swatchBuilder(l.color),
                title: Text(l.name?.isNotEmpty == true ? l.name! : l.color),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (action) => _onAction(l, action),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            const Divider(),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'New label name'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in kLabelColorNames)
                  InkWell(
                    onTap: () => setState(() => _color = c),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: labelColor(c),
                        borderRadius: BorderRadius.circular(6),
                        border: _color == c
                            ? Border.all(
                                width: 3,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            widget.onCreate(_nameCtrl.text.trim(), _color);
            Navigator.pop(context);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
