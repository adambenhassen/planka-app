import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../api/models.dart';
import '../api/planka_api.dart';
import '../auth/auth_providers.dart';
import '../l10n/gen/app_localizations.dart';
import '../state/board_state.dart';
import 'theme/app_theme.dart';
import 'widgets/label_colors.dart';

/// Cover thumbnail URL for a card, or null when it has no image cover.
/// Planka serves attachment images under data.thumbnailUrls (absolute URLs).
String? cardCoverUrl(PlankaCard card, BoardState state) {
  final id = card.coverAttachmentId;
  if (id == null) return null;
  final cover = state.attachments.where((a) => a.id == id).firstOrNull;
  return cover?.coverThumbnailUrl;
}

/// Compact age for a card tile, from the same field the web client renders
/// its age display from (createdAt): "now", "45m", "3h", "2d".
String cardAgeLabel(DateTime createdAt, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(createdAt);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  return '${d.inDays}d';
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
    // The creator shown when the board asks for it; a user row the board
    // response does not carry still renders, as an unknown-initial avatar.
    final creator =
        state.users.where((u) => u.id == card.creatorUserId).firstOrNull;
    final tasks = state.tasksOfCard(card.id);
    final done = tasks.where(state.isTaskCompleted).length;
    final attachmentCount = state.attachmentsOf(card.id).length;
    final customFields = state.frontOfCardCustomFieldsOf(card.id);
    final due = card.dueDate;
    // Per-board display settings; all default to off and leave the tile as it
    // was before they existed.
    final showCreator = state.board.alwaysDisplayCardCreator == true;
    final showAge = state.board.displayCardAges == true;
    final expandTaskLists = state.board.expandTaskListsByDefault == true;
    final commentsTotal = card.commentsTotal ?? 0;
    // The server derives this from the list type; derive it locally too so a
    // move whose broadcast has not landed yet still shows the right state.
    final isClosed = card.isClosed == true ||
        state.lists.where((l) => l.id == card.listId).firstOrNull?.type ==
            PlankaListType.closed;
    final hasBottomRow = due != null ||
        (tasks.isNotEmpty && !expandTaskLists) ||
        attachmentCount > 0 ||
        members.isNotEmpty ||
        commentsTotal > 0 ||
        isClosed ||
        (showCreator && card.creatorUserId != null) ||
        (showAge && card.createdAt != null);

    // Downloads authenticate via the accessToken cookie, not a Bearer header.
    final token = ref.watch(currentAccountProvider)?.token;

    return Card(
      color: context.tokens.cardSurface,
      // Horizontal inset only; the 8px inter-card gap comes from the drop
      // target between cards, matching Planka's 8px card margin-bottom.
      margin: const EdgeInsets.symmetric(horizontal: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (coverUrl != null && token != null)
              CachedNetworkImage(
                imageUrl: coverUrl,
                httpHeaders: imageAuthHeaders(token),
                width: double.infinity,
                fit: BoxFit.fitWidth,
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
                  Text(card.name,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  if (customFields.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final (field, value) in customFields)
                          _CustomFieldChip(field: field, value: value),
                      ],
                    ),
                  ],
                  if (expandTaskLists) _InlineTaskLists(state: state, cardId: card.id),
                  if (hasBottomRow) ...[
                    const SizedBox(height: 8),
                    // Split layout: the chips wrap (each keeps its own 8px
                    // trailing gap, so single-line spacing is unchanged) while
                    // the avatar group stays a fixed-width block on the right,
                    // bottom-aligned. A single non-wrapping Row overflows the
                    // 300px column once every chip and avatar is present.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 0,
                            runSpacing: 8,
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
                              if (tasks.isNotEmpty && !expandTaskLists)
                                _Chip(
                                  icon: Icons.check_box_outlined,
                                  label: '$done/${tasks.length}',
                                ),
                              if (attachmentCount > 0)
                                _Chip(
                                  icon: Icons.attach_file,
                                  label: '$attachmentCount',
                                ),
                              if (commentsTotal > 0)
                                _Chip(
                                  icon: Icons.comment_outlined,
                                  label: '$commentsTotal',
                                ),
                              if (showAge && card.createdAt != null)
                                _Chip(
                                  icon: Icons.history,
                                  label: cardAgeLabel(card.createdAt!),
                                ),
                              if (isClosed)
                                _Chip(
                                  icon: Icons.inventory_2_outlined,
                                  label: AppLocalizations.of(context).cardClosed,
                                ),
                            ],
                          ),
                        ),
                        if (showCreator && card.creatorUserId != null) ...[
                          CircleAvatar(
                            radius: 12,
                            child: Text(
                              (creator?.name.isEmpty ?? true)
                                  ? '?'
                                  : creator!.name[0].toUpperCase(),
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                          if (members.isNotEmpty)
                            Container(
                              width: 1,
                              height: 16,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                        ],
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

/// A value that opens with a number, matching what JS `parseFloat` accepts —
/// trailing text and all, so `42 units` counts. Dart's `double.tryParse` wants
/// the whole string to be a number and would miss it.
final _leadingNumber = RegExp(r'^\s*[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?');

/// A front-of-card custom field value. The web client shows the value alone,
/// prefixing it with the field name only when the value opens with a number
/// and would otherwise say nothing about what it measures.
class _CustomFieldChip extends StatelessWidget {
  const _CustomFieldChip({required this.field, required this.value});
  final PlankaCustomField field;
  final PlankaCustomFieldValue value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _leadingNumber.hasMatch(value.content)
        ? '${field.name}: ${value.content}'
        : value.content;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// A card's checklists rendered inline on the tile, expanded by default per
/// the board's expandTaskListsByDefault; the progress-row header toggles each
/// one closed, leaving the same done/total count the collapsed web tile shows.
class _InlineTaskLists extends StatefulWidget {
  const _InlineTaskLists({required this.state, required this.cardId});
  final BoardState state;
  final String cardId;

  @override
  State<_InlineTaskLists> createState() => _InlineTaskListsState();
}

class _InlineTaskListsState extends State<_InlineTaskLists> {
  final Set<String> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = <Widget>[];
    for (final tl in widget.state.taskListsOf(widget.cardId)) {
      final tasks = widget.state.tasks.where((t) => t.taskListId == tl.id).toList();
      if (tasks.isEmpty) continue;
      final done = tasks.where((t) => t.isCompleted).length;
      final isExpanded = !_collapsed.contains(tl.id);
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: ValueKey('tile-tasklist-toggle-${tl.id}'),
              onTap: () => setState(() {
                isExpanded ? _collapsed.add(tl.id) : _collapsed.remove(tl.id);
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                          value: done / tasks.length,
                          minHeight: 3,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 6),
                    Text('$done/${tasks.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              for (final t in tasks)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 2),
                  child: Row(
                    children: [
                      Icon(
                        t.isCompleted
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          t.name,
                          style: theme.textTheme.labelSmall?.copyWith(
                            decoration: t.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 4),
          ],
        ),
      );
    }
    if (sections.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(children: sections),
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
