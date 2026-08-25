import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../api/models.dart';
import '../api/planka_api.dart';
import 'custom_fields_manager_sheet.dart';
import '../auth/auth_providers.dart';
import '../l10n/gen/app_localizations.dart';
import 'error_handling.dart';
import 'widgets/confirm_dialog.dart';
import 'widgets/move_card_dialog.dart';
import '../state/board_state.dart';
import 'card_sections/activity.dart';
import 'card_sections/attachments.dart';
import 'card_sections/comments.dart';
import 'card_sections/custom_fields.dart';
import 'card_sections/due_date.dart';
import 'card_sections/header.dart';
import 'card_sections/labels.dart';
import 'card_sections/members.dart';
import 'card_sections/stopwatch.dart';
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

  /// Closes the sheet, then runs [run] detached, surfacing any failure via a
  /// snackbar on the messenger captured before the pop (this sheet's context is
  /// gone by the time the mutation resolves).
  void _popAndRun(BuildContext context, Future<void> Function() run) {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    Navigator.pop(context);
    run().catchError((Object e) {
      final message = e is ApiException ? e.message : '$e';
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: errorColor),
      );
    });
  }

  /// Downloads an attachment to the temp dir (cookie-authenticated, root-level
  /// download route) and opens it with the platform default app.
  Future<void> _openAttachment(
      AppLocalizations l10n, PlankaApi api, PlankaAttachment a) async {
    final dir = await getTemporaryDirectory();
    // Attachment names are user-supplied; strip path separators so they can't
    // escape the temp directory.
    final safeName = a.name.replaceAll(RegExp(r'[/\\]'), '_');
    final path = '${dir.path}/planka-${a.id}-$safeName';
    await api.download(
        '/attachments/${a.id}/download/${Uri.encodeComponent(a.name)}', path);
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw ApiException(
          null, l10n.cardOpenAttachmentFailed(a.name, result.message));
    }
  }

  /// Opens the move dialog; if the card left this board, closes the sheet too
  /// since it no longer has anything to show.
  Future<void> _showMoveDialog(BuildContext context) async {
    final moved = await showMoveCardDialog(context, boardId, cardId);
    if (moved && context.mounted) Navigator.pop(context);
  }

  /// Confirms, then optimistically deletes the card and closes the sheet.
  Future<void> _confirmDelete(
      BuildContext context, BoardNotifier notifier) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDialog(context,
        title: l10n.cardDeleteTitle,
        message: l10n.cardDeleteMessage,
        confirmLabel: l10n.actionDelete);
    if (!confirmed || !context.mounted) return;
    _popAndRun(context, () => notifier.deleteCard(cardId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(boardProvider(boardId)).value;
    final card = state?.cards[cardId];
    if (state == null || card == null) {
      return SizedBox(
          height: 200, child: Center(child: Text(l10n.cardGone)));
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
              icon: Icon(card.isSubscribed == true
                  ? Icons.notifications_active
                  : Icons.notifications_none),
              tooltip: card.isSubscribed == true
                  ? l10n.cardUnwatch
                  : l10n.cardWatch,
              onPressed: () => guardMutation(context,
                  notifier.setSubscribed(cardId, card.isSubscribed != true)),
            ),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: l10n.cardDuplicate,
              onPressed: () => guardMutation(
                  context, notifier.duplicateCard(cardId)),
            ),
            IconButton(
              icon: const Icon(Icons.drive_file_move_outlined),
              tooltip: l10n.cardMove,
              onPressed: () => _showMoveDialog(context),
            ),
            if (state.lists.any((l) => l.type == PlankaListType.archive))
              IconButton(
                icon: const Icon(Icons.archive_outlined),
                tooltip: l10n.cardArchive,
                onPressed: () =>
                    _popAndRun(context, () => notifier.archiveCard(cardId)),
              ),
            if (state.lists.any((l) => l.type == PlankaListType.trash))
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: l10n.cardMoveToTrash,
                onPressed: () => _popAndRun(
                    context, () => notifier.moveCardToTrash(cardId)),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.cardDelete,
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
          l10n.sectionStopwatch,
          CardStopwatchSection(
            stopwatch: card.stopwatch,
            onStart: (total) => guardMutation(
                context,
                notifier.setStopwatch(cardId,
                    startedAt: DateTime.now().toUtc(), total: total)),
            onPause: (total) => guardMutation(
                context, notifier.setStopwatch(cardId, total: total)),
            onReset: () =>
                guardMutation(context, notifier.clearStopwatch(cardId)),
          ),
        ),
        section(
          l10n.sectionLabels,
          CardLabelsSection(
            boardLabels: state.labels,
            activeLabelIds:
                state.labelsOf(cardId).map((l) => l.id).toSet(),
            onToggle: (labelId) =>
                guardMutation(context, notifier.toggleLabel(cardId, labelId)),
            onCreate: (name, color) => guardMutation(
                context,
                notifier.createLabel(color, name: name.isEmpty ? null : name)),
            onEditLabel: (id, name) =>
                guardMutation(context, notifier.editLabel(id, name: name)),
            onDeleteLabel: (id) =>
                guardMutation(context, notifier.deleteLabel(id)),
          ),
        ),
        section(
          l10n.sectionMembers,
          CardMembersSection(
            boardUsers: state.users,
            memberUserIds: state.membersOf(cardId).map((u) => u.id).toSet(),
            onToggle: (userId) =>
                guardMutation(context, notifier.toggleMember(cardId, userId)),
          ),
        ),
        // Immediately before the checklists, where the web client puts them.
        // A board with no custom fields adds no section at all.
        for (final group in state.customFieldGroupsOf(cardId))
          section(
            state.customFieldGroupName(group),
            CardCustomFieldsSection(
              entries: [
                for (final field in state.customFieldsOf(group))
                  (field, state.customFieldValueOf(cardId, group.id, field.id)),
              ],
              onChanged: (field, content) => guardMutation(
                  context,
                  notifier.setCustomFieldValue(cardId,
                      groupId: group.id,
                      fieldId: field.id,
                      content: content)),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.tune, size: 18),
            label: Text(l10n.customFieldsTitle),
            onPressed: () => showCustomFieldsManagerSheet(context,
                boardId: boardId, cardId: cardId),
          ),
        ),
        section(
          l10n.sectionChecklists,
          CardTaskListsSection(
            taskLists: cardTaskLists,
            tasks: state.tasks,
            users: state.boardMembers,
            isTaskCompleted: state.isTaskCompleted,
            linkedCardNameOf: (t) => t.linkedCardId == null
                ? null
                : state.cards[t.linkedCardId]?.name,
            onToggleTask: (taskId, v) =>
                guardMutation(context, notifier.setTaskCompleted(taskId, v)),
            onSetAssignee: (taskId, userId) => guardMutation(
                context, notifier.setTaskAssignee(taskId, userId)),
            onOpenLinkedCard: (linkedCardId) =>
                showCardSheet(context, boardId, linkedCardId),
            onAddTask: (taskListId, name) =>
                guardMutation(context, notifier.createTask(taskListId, name)),
            onAddTaskList: (name) =>
                guardMutation(context, notifier.createTaskList(cardId, name)),
            onRenameTaskList: (id, name) =>
                guardMutation(context, notifier.renameTaskList(id, name)),
            onDeleteTaskList: (id) =>
                guardMutation(context, notifier.deleteTaskList(id)),
            onRenameTask: (id, name) =>
                guardMutation(context, notifier.renameTask(id, name)),
            onDeleteTask: (id) =>
                guardMutation(context, notifier.deleteTask(id)),
          ),
        ),
        section(
          l10n.sectionAttachments,
          CardAttachmentsSection(
            attachments: state.attachmentsOf(cardId),
            token: account?.token,
            coverAttachmentId: card.coverAttachmentId,
            onSetCover: (id) =>
                guardMutation(context, notifier.setCover(cardId, id)),
            onOpen: (a) => guardMutation(
                context, _openAttachment(l10n, ref.read(apiProvider), a)),
            onUpload: (path, name) =>
                guardMutation(context,
                    notifier.uploadAttachment(cardId, filePath: path, name: name)),
            onDelete: (id) => guardMutation(context, notifier.deleteAttachment(id)),
          ),
        ),
        section(
          l10n.sectionComments,
          CardCommentsSection(
            comments: comments,
            users: state.users,
            currentUserId: account?.userId ?? '',
            onSend: (text) => guardMutation(context, notifier.createComment(cardId, text)),
            onEdit: (id, text) =>
                guardMutation(context, notifier.editComment(id, text)),
            onDelete: (id) => guardMutation(context, notifier.deleteComment(id)),
          ),
        ),
        section(
          l10n.sectionActivity,
          CardActivitySection(cardId: cardId, users: state.users),
        ),
      ],
    );
  }
}
