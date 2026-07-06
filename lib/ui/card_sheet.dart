import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/planka_api.dart';
import '../auth/auth_providers.dart';
import '../state/board_state.dart';
import 'card_sections/attachments.dart';
import 'card_sections/comments.dart';
import 'card_sections/due_date.dart';
import 'card_sections/header.dart';
import 'card_sections/labels.dart';
import 'card_sections/members.dart';
import 'card_sections/task_lists.dart';

Future<void> showCardSheet(
    BuildContext context, String boardId, String cardId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 1,
      builder: (context, scrollController) => CardSheet(
        boardId: boardId,
        cardId: cardId,
        scrollController: scrollController,
      ),
    ),
  );
}

class CardSheet extends ConsumerWidget {
  const CardSheet({
    super.key,
    required this.boardId,
    required this.cardId,
    this.scrollController,
  });

  final String boardId;
  final String cardId;
  final ScrollController? scrollController;

  void _guard(BuildContext context, Future<void> future) {
    future.catchError((Object e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : '$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(boardProvider(boardId)).value;
    final card = state?.cards[cardId];
    if (state == null || card == null) {
      return const SizedBox(
          height: 200, child: Center(child: Text('Card no longer exists')));
    }
    final notifier = ref.read(boardProvider(boardId).notifier);
    final account = ref.watch(currentAccountProvider);
    final cardTaskLists =
        state.taskLists.where((t) => t.cardId == cardId).toList()
          ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
    final comments = state.comments.where((c) => c.cardId == cardId).toList()
      ..sort((a, b) => (a.createdAt ?? DateTime(0))
          .compareTo(b.createdAt ?? DateTime(0)));

    Widget section(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              child,
            ],
          ),
        );

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(
          child: Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        CardHeaderSection(
          card: card,
          onRename: (name) => _guard(context, notifier.renameCard(cardId, name)),
          onDescriptionChanged: (desc) =>
              _guard(context, notifier.updateCard(cardId, {'description': desc})),
        ),
        CardDueDateSection(
          card: card,
          onChanged: (d) => _guard(context, notifier.setDueDate(cardId, d)),
          onCompletedToggle: (v) =>
              _guard(context, notifier.updateCard(cardId, {'isDueCompleted': v})),
        ),
        section(
          'Labels',
          CardLabelsSection(
            boardLabels: state.labels,
            activeLabelIds: state.cardLabels
                .where((cl) => cl.cardId == cardId)
                .map((cl) => cl.labelId)
                .toSet(),
            onToggle: (labelId) =>
                _guard(context, notifier.toggleLabel(cardId, labelId)),
            onCreate: (name, color) => _guard(
                context,
                notifier.createLabel(
                    name: name.isEmpty ? null : name, color: color)),
          ),
        ),
        section(
          'Members',
          CardMembersSection(
            boardUsers: state.users,
            memberUserIds: state.cardMemberships
                .where((m) => m.cardId == cardId)
                .map((m) => m.userId)
                .toSet(),
            onToggle: (userId) =>
                _guard(context, notifier.toggleMember(cardId, userId)),
          ),
        ),
        section(
          'Checklists',
          CardTaskListsSection(
            taskLists: cardTaskLists,
            tasks: state.tasks,
            onToggleTask: (taskId, v) =>
                _guard(context, notifier.toggleTask(taskId, v)),
            onAddTask: (taskListId, name) =>
                _guard(context, notifier.addTask(taskListId, name)),
            onAddTaskList: (name) =>
                _guard(context, notifier.addTaskList(cardId, name)),
          ),
        ),
        section(
          'Attachments',
          CardAttachmentsSection(
            attachments:
                state.attachments.where((a) => a.cardId == cardId).toList(),
            serverUrl: account?.serverUrl ?? '',
            token: account?.token ?? '',
            onUpload: (path, name) =>
                _guard(context, notifier.uploadAttachment(cardId, path, name)),
            onDelete: (id) => _guard(context, notifier.deleteAttachment(id)),
          ),
        ),
        section(
          'Comments',
          CardCommentsSection(
            comments: comments,
            users: state.users,
            currentUserId: account?.userId ?? '',
            onSend: (text) => _guard(context, notifier.addComment(cardId, text)),
            onDelete: (id) => _guard(context, notifier.deleteComment(id)),
          ),
        ),
      ],
    );
  }
}
