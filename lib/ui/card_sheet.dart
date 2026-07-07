import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/planka_api.dart';
import '../auth/auth_providers.dart';
import 'error_handling.dart';
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

  /// Confirms, then optimistically deletes the card and closes the sheet.
  /// The messenger is captured before popping so a failed delete still surfaces
  /// after this sheet's context is gone.
  Future<void> _confirmDelete(
      BuildContext context, BoardNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete card?'),
        content: const Text('This card will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    Navigator.pop(context);
    notifier.deleteCard(cardId).catchError((Object e) {
      final message = e is ApiException ? e.message : '$e';
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: errorColor),
      );
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
    final cardTaskLists = state.taskListsOf(cardId);
    final comments = state.commentsOf(cardId);

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
        Row(
          children: [
            const SizedBox(width: 48),
            Expanded(
              child: Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete card',
              onPressed: () => _confirmDelete(context, notifier),
            ),
          ],
        ),
        CardHeaderSection(
          card: card,
          onRename: (name) => guardMutation(context, notifier.renameCard(cardId, name)),
          onDescriptionChanged: (desc) =>
              guardMutation(context, notifier.setDescription(cardId, desc)),
        ),
        CardDueDateSection(
          card: card,
          onChanged: (d) => guardMutation(context, notifier.setDueDate(cardId, d)),
          onCompletedToggle: (v) =>
              guardMutation(context, notifier.setDueCompleted(cardId, v)),
        ),
        section(
          'Labels',
          CardLabelsSection(
            boardLabels: state.labels,
            activeLabelIds:
                state.labelsOf(cardId).map((l) => l.id).toSet(),
            onToggle: (labelId) =>
                guardMutation(context, notifier.toggleLabel(cardId, labelId)),
            onCreate: (name, color) => guardMutation(
                context,
                notifier.createLabel(color, name: name.isEmpty ? null : name)),
          ),
        ),
        section(
          'Members',
          CardMembersSection(
            boardUsers: state.users,
            memberUserIds: state.membersOf(cardId).map((u) => u.id).toSet(),
            onToggle: (userId) =>
                guardMutation(context, notifier.toggleMember(cardId, userId)),
          ),
        ),
        section(
          'Checklists',
          CardTaskListsSection(
            taskLists: cardTaskLists,
            tasks: state.tasks,
            onToggleTask: (taskId, v) =>
                guardMutation(context, notifier.setTaskCompleted(taskId, v)),
            onAddTask: (taskListId, name) =>
                guardMutation(context, notifier.createTask(taskListId, name)),
            onAddTaskList: (name) =>
                guardMutation(context, notifier.createTaskList(cardId, name)),
          ),
        ),
        section(
          'Attachments',
          CardAttachmentsSection(
            attachments: state.attachmentsOf(cardId),
            token: account?.token,
            onUpload: (path, name) =>
                guardMutation(context,
                    notifier.uploadAttachment(cardId, filePath: path, name: name)),
            onDelete: (id) => guardMutation(context, notifier.deleteAttachment(id)),
          ),
        ),
        section(
          'Comments',
          CardCommentsSection(
            comments: comments,
            users: state.users,
            currentUserId: account?.userId ?? '',
            onSend: (text) => guardMutation(context, notifier.createComment(cardId, text)),
            onDelete: (id) => guardMutation(context, notifier.deleteComment(id)),
          ),
        ),
      ],
    );
  }
}
