import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/inline_add_field.dart';
import '../widgets/prompt_dialog.dart';

class CardTaskListsSection extends StatelessWidget {
  const CardTaskListsSection({
    super.key,
    required this.taskLists,
    required this.tasks,
    required this.users,
    required this.isTaskCompleted,
    required this.linkedCardNameOf,
    required this.onToggleTask,
    required this.onAddTask,
    required this.onAddTaskList,
    required this.onRenameTaskList,
    required this.onDeleteTaskList,
    required this.onRenameTask,
    required this.onDeleteTask,
    required this.onSetAssignee,
    required this.onOpenLinkedCard,
  });

  final List<PlankaTaskList> taskLists;
  final List<PlankaTask> tasks;

  /// The board members a checklist item can be assigned to.
  final List<PlankaUser> users;

  /// A linked item's completion mirrors its card (see [BoardState]);
  /// an unlinked item's is its own flag.
  final bool Function(PlankaTask) isTaskCompleted;

  /// The display name of the card an item links to, null when unlinked or
  /// when that card is not on this board.
  final String? Function(PlankaTask) linkedCardNameOf;
  final void Function(String taskId, bool isCompleted) onToggleTask;
  final void Function(String taskListId, String name) onAddTask;
  final ValueChanged<String> onAddTaskList;
  final void Function(String taskListId, String name) onRenameTaskList;
  final ValueChanged<String> onDeleteTaskList;
  final void Function(String taskId, String name) onRenameTask;
  final ValueChanged<String> onDeleteTask;

  /// Assigns [userId] to the item, or unassigns with null.
  final void Function(String taskId, String? userId) onSetAssignee;

  /// Opens the card an item links to.
  final ValueChanged<String> onOpenLinkedCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tl in taskLists) ...[
          _TaskList(
            taskList: tl,
            tasks: tasks.where((t) => t.taskListId == tl.id).toList(),
            users: users,
            isTaskCompleted: isTaskCompleted,
            linkedCardNameOf: linkedCardNameOf,
            onToggleTask: onToggleTask,
            onAddTask: (name) => onAddTask(tl.id, name),
            onRenameTaskList: onRenameTaskList,
            onDeleteTaskList: onDeleteTaskList,
            onRenameTask: onRenameTask,
            onDeleteTask: onDeleteTask,
            onSetAssignee: onSetAssignee,
            onOpenLinkedCard: onOpenLinkedCard,
          ),
          const SizedBox(height: 8),
        ],
        InlineAddField(
            label: AppLocalizations.of(context).checklistAdd,
            onSubmit: onAddTaskList),
      ],
    );
  }
}

/// The assignee picker for a checklist item, over the board's members.
Future<String?> _pickAssignee(
        BuildContext context, List<PlankaUser> users, String? currentUserId) =>
    showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context).taskAssign),
        children: [
          for (final u in users)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, u.id),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase()),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(u.name)),
                  if (u.id == currentUserId) const Icon(Icons.check, size: 18),
                ],
              ),
            ),
        ],
      ),
    );

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.taskList,
    required this.tasks,
    required this.users,
    required this.isTaskCompleted,
    required this.linkedCardNameOf,
    required this.onToggleTask,
    required this.onAddTask,
    required this.onRenameTaskList,
    required this.onDeleteTaskList,
    required this.onRenameTask,
    required this.onDeleteTask,
    required this.onSetAssignee,
    required this.onOpenLinkedCard,
  });

  final PlankaTaskList taskList;
  final List<PlankaTask> tasks;
  final List<PlankaUser> users;
  final bool Function(PlankaTask) isTaskCompleted;
  final String? Function(PlankaTask) linkedCardNameOf;
  final void Function(String taskId, bool isCompleted) onToggleTask;
  final ValueChanged<String> onAddTask;
  final void Function(String taskListId, String name) onRenameTaskList;
  final ValueChanged<String> onDeleteTaskList;
  final void Function(String taskId, String name) onRenameTask;
  final ValueChanged<String> onDeleteTask;
  final void Function(String taskId, String? userId) onSetAssignee;
  final ValueChanged<String> onOpenLinkedCard;

  PlankaUser? _assigneeOf(PlankaTask t) => t.assigneeUserId == null
      ? null
      : users.where((u) => u.id == t.assigneeUserId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final done = tasks.where(isTaskCompleted).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(taskList.name,
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (action) async {
                if (action == 'rename') {
                  final name = await promptText(context,
                      title: l10n.checklistRenameTitle,
                      initialValue: taskList.name);
                  if (!context.mounted || name == null) return;
                  onRenameTaskList(taskList.id, name);
                } else if (action == 'delete') {
                  final ok = await confirmDialog(context,
                      title: l10n.checklistDeleteTitle,
                      message: l10n.checklistDeleteMessage,
                      confirmLabel: l10n.actionDelete);
                  if (!context.mounted || !ok) return;
                  onDeleteTaskList(taskList.id);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'rename', child: Text(l10n.actionRename)),
                PopupMenuItem(value: 'delete', child: Text(l10n.actionDelete)),
              ],
            ),
          ],
        ),
        if (tasks.isNotEmpty) ...[
          const SizedBox(height: 4),
          LinearProgressIndicator(value: done / tasks.length),
        ],
        for (final t in tasks)
          GestureDetector(
            // A linked item opens its card; an unlinked one leaves the row to
            // the checkbox alone.
            behavior: HitTestBehavior.opaque,
            onTap: t.linkedCardId == null
                ? null
                : () => onOpenLinkedCard(t.linkedCardId!),
            child: CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              // A linked item's checkbox mirrors its card; completion changes
              // only when that card moves in or out of a closed list.
              value: isTaskCompleted(t),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.name,
                    style: isTaskCompleted(t)
                        ? const TextStyle(decoration: TextDecoration.lineThrough)
                        : null,
                  ),
                  if (_assigneeOf(t) case final assignee?)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 8,
                            child: Text(assignee.name.isEmpty
                                ? '?'
                                : assignee.name[0].toUpperCase()),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(assignee.name,
                                style: Theme.of(context).textTheme.labelSmall),
                          ),
                        ],
                      ),
                    ),
                  if (linkedCardNameOf(t) case final cardName?)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link,
                              size: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(cardName,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              secondary: PopupMenuButton<String>(
                key: Key('task-menu-${t.id}'),
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (action) async {
                  if (action == 'rename') {
                    final name = await promptText(context,
                        title: l10n.taskRenameTitle, initialValue: t.name);
                    if (!context.mounted || name == null) return;
                    onRenameTask(t.id, name);
                  } else if (action == 'delete') {
                    final ok = await confirmDialog(context,
                        title: l10n.taskDeleteTitle,
                        confirmLabel: l10n.actionDelete);
                    if (!context.mounted || !ok) return;
                    onDeleteTask(t.id);
                  } else if (action == 'assign') {
                    final userId =
                        await _pickAssignee(context, users, t.assigneeUserId);
                    if (!context.mounted || userId == null) return;
                    onSetAssignee(t.id, userId);
                  } else if (action == 'unassign') {
                    onSetAssignee(t.id, null);
                  }
                },
                // A linked task only accepts move/delete server-side: its name
                // and completion mirror the card, so rename and assign are left
                // out rather than offered as guaranteed failures.
                itemBuilder: (_) => [
                  if (t.linkedCardId == null)
                    PopupMenuItem(
                        value: 'rename', child: Text(l10n.actionRename)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.actionDelete)),
                  if (t.linkedCardId == null) ...[
                    PopupMenuItem(value: 'assign', child: Text(l10n.taskAssign)),
                    if (t.assigneeUserId != null)
                      PopupMenuItem(
                          value: 'unassign', child: Text(l10n.taskUnassign)),
                  ],
                ],
              ),
              onChanged: t.linkedCardId != null
                  ? null
                  : (v) => onToggleTask(t.id, v ?? false),
            ),
          ),
        InlineAddField(label: l10n.taskAdd, onSubmit: onAddTask),
      ],
    );
  }
}
