import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api/models.dart';
import '../../api/planka_api.dart';
import '../../auth/auth_providers.dart';
import '../../state/board_state.dart';
import 'label_colors.dart';

/// Cover thumbnail URL for a card, or null when it has no image cover.
/// Planka serves attachment images under data.thumbnailUrls (absolute URLs).
String? cardCoverUrl(PlankaCard card, BoardState state) {
  final id = card.coverAttachmentId;
  if (id == null) return null;
  final cover = state.attachments.where((a) => a.id == id).firstOrNull;
  final thumbs = cover?.data?['thumbnailUrls'];
  if (thumbs is! Map) return null;
  return (thumbs['outside720'] ?? thumbs['outside360']) as String?;
}

class CardTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coverUrl = cardCoverUrl(card, state);
    final labels = state.labelsOf(card.id);
    final members = state.membersOf(card.id);
    final tasks = state.tasksOfCard(card.id);
    final done = tasks.where((t) => t.isCompleted).length;
    final attachmentCount = state.attachmentsOf(card.id).length;
    final due = card.dueDate;

    // Downloads authenticate via the accessToken cookie, not a Bearer header.
    final token = ref.watch(currentAccountProvider)?.token;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (coverUrl != null && token != null)
              CachedNetworkImage(
                imageUrl: coverUrl,
                httpHeaders: imageAuthHeaders(token),
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            Padding(
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
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: labelColor(l.color),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l.name ?? '',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                              ),
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
                          _Chip(
                            icon: Icons.check_box_outlined,
                            label: '$done/${tasks.length}',
                          ),
                        if (attachmentCount > 0)
                          _Chip(
                            icon: Icons.attach_file,
                            label: '$attachmentCount',
                          ),
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
          ],
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
