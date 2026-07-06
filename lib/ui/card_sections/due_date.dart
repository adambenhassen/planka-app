import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/models.dart';

class CardDueDateSection extends StatelessWidget {
  const CardDueDateSection({
    super.key,
    required this.card,
    required this.onChanged,
    required this.onCompletedToggle,
  });

  final PlankaCard card;
  final ValueChanged<DateTime?> onChanged;
  final ValueChanged<bool> onCompletedToggle;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = card.dueDate?.toLocal() ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    onChanged(DateTime(date.year, date.month, date.day, time?.hour ?? 12,
        time?.minute ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final due = card.dueDate?.toLocal();
    return Row(
      children: [
        if (due != null)
          Checkbox(
            value: card.isDueCompleted ?? false,
            onChanged: (v) => onCompletedToggle(v ?? false),
          ),
        TextButton.icon(
          icon: const Icon(Icons.schedule),
          label: Text(due == null
              ? 'Set due date'
              : DateFormat.yMMMd().add_Hm().format(due)),
          onPressed: () => _pick(context),
        ),
        if (due != null)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Remove due date',
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }
}
