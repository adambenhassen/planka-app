import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/models.dart';
import '../../state/board_state.dart';

/// Planka label color names → display colors (subset of Planka's palette;
/// unknown names fall back to a neutral).
const _labelColors = <String, Color>{
  'berry-red': Color(0xFFE04556),
  'pumpkin-orange': Color(0xFFF0982D),
  'lagoon-blue': Color(0xFF109DC0),
  'pink-tulip': Color(0xFFF97394),
  'light-mud': Color(0xFFC7A57B),
  'orange-peel': Color(0xFFFAB623),
  'bright-moss': Color(0xFFA5C261),
  'antique-blue': Color(0xFF6A85A0),
  'dark-granite': Color(0xFF8B8680),
  'turquoise-sea': Color(0xFF29A886),
  'lagune-blue': Color(0xFF109DC0),
  'sunny-grass': Color(0xFFBDC847),
  'morning-sky': Color(0xFF66A8D4),
  'light-orange': Color(0xFFECA66E),
  'midnight-blue': Color(0xFF2B394F),
  'tank-green': Color(0xFF9AA177),
  'gun-metal': Color(0xFF5C6772),
  'wet-moss': Color(0xFF3F8955),
  'red-burgundy': Color(0xFFAD5F7D),
  'light-concrete': Color(0xFFAFB0A4),
  'apricot-red': Color(0xFFF56B62),
  'desert-sand': Color(0xFFEDCB76),
  'navy-blue': Color(0xFF16344D),
  'egg-yellow': Color(0xFFF7D036),
  'coral-green': Color(0xFF4FD683),
  'light-cocoa': Color(0xFFAD8D71),
};

Color labelColor(String name) => _labelColors[name] ?? const Color(0xFF8B8680);

class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    required this.card,
    required this.state,
    this.onTap,
  });

  final PlankaCard card;
  final BoardState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = state.cardLabels
        .where((cl) => cl.cardId == card.id)
        .map((cl) =>
            state.labels.where((l) => l.id == cl.labelId).firstOrNull)
        .nonNulls
        .toList();
    final members = state.cardMemberships
        .where((m) => m.cardId == card.id)
        .map((m) => state.users.where((u) => u.id == m.userId).firstOrNull)
        .nonNulls
        .toList();
    final taskListIds =
        state.taskLists.where((t) => t.cardId == card.id).map((t) => t.id).toSet();
    final tasks =
        state.tasks.where((t) => taskListIds.contains(t.taskListId)).toList();
    final done = tasks.where((t) => t.isCompleted).length;
    final attachmentCount =
        state.attachments.where((a) => a.cardId == card.id).length;
    final due = card.dueDate;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (labels.isNotEmpty) ...[
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final l in labels)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: labelColor(l.color),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l.name ?? '',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(card.name, style: theme.textTheme.bodyLarge),
              if (due != null ||
                  tasks.isNotEmpty ||
                  attachmentCount > 0 ||
                  members.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (due != null)
                      _Chip(
                        icon: Icons.schedule,
                        label: DateFormat.MMMd().format(due.toLocal()),
                        color: card.isDueCompleted == true
                            ? theme.colorScheme.tertiary
                            : (due.isBefore(DateTime.now())
                                ? theme.colorScheme.error
                                : null),
                      ),
                    if (tasks.isNotEmpty)
                      _Chip(icon: Icons.check_box_outlined, label: '$done/${tasks.length}'),
                    if (attachmentCount > 0)
                      _Chip(icon: Icons.attach_file, label: '$attachmentCount'),
                    const Spacer(),
                    for (final u in members.take(3))
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: CircleAvatar(
                          radius: 12,
                          child: Text(
                            u.name.isEmpty ? '?' : u.name[0].toUpperCase(),
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 2),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: c)),
        ],
      ),
    );
  }
}
