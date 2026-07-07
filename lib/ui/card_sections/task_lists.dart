import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/inline_add_field.dart';
import '../widgets/prompt_dialog.dart';

class CardTaskListsSection extends StatelessWidget {
  const CardTaskListsSection({
    super.key,
    required this.taskLists,
    required this.tasks,
    required this.onToggleTask,
    required this.onAddTask,
    required this.onAddTaskList,
    required this.onRenameTaskList,
    required this.onDeleteTaskList,
    required this.onRenameTask,
    required this.onDeleteTask,
  });

  final List<PlankaTaskList> taskLists;
  final List<PlankaTask> tasks;
  final void Function(String taskId, bool isCompleted) onToggleTask;
  final void Function(String taskListId, String name) onAddTask;
  final ValueChanged<String> onAddTaskList;
  final void Function(String taskListId, String name) onRenameTaskList;
  final ValueChanged<String> onDeleteTaskList;
  final void Function(String taskId, String name) onRenameTask;
  final ValueChanged<String> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tl in taskLists) ...[
          _TaskList(
            taskList: tl,
            tasks: tasks.where((t) => t.taskListId == tl.id).toList(),
            onToggleTask: onToggleTask,
            onAddTask: (name) => onAddTask(tl.id, name),
            onRenameTaskList: onRenameTaskList,
            onDeleteTaskList: onDeleteTaskList,
            onRenameTask: onRenameTask,
            onDeleteTask: onDeleteTask,
          ),
          const SizedBox(height: 8),
        ],
        InlineAddField(label: 'Add checklist', onSubmit: onAddTaskList),
      ],
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.taskList,
    required this.tasks,
    required this.onToggleTask,
    required this.onAddTask,
    required this.onRenameTaskList,
    required this.onDeleteTaskList,
    required this.onRenameTask,
    required this.onDeleteTask,
  });

  final PlankaTaskList taskList;
  final List<PlankaTask> tasks;
  final void Function(String taskId, bool isCompleted) onToggleTask;
  final ValueChanged<String> onAddTask;
  final void Function(String taskListId, String name) onRenameTaskList;
  final ValueChanged<String> onDeleteTaskList;
  final void Function(String taskId, String name) onRenameTask;
  final ValueChanged<String> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => t.isCompleted).length;
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
                      title: 'Rename checklist', initialValue: taskList.name);
                  if (!context.mounted || name == null) return;
                  onRenameTaskList(taskList.id, name);
                } else if (action == 'delete') {
                  final ok = await confirmDialog(context,
                      title: 'Delete checklist?',
                      message: 'The checklist and its tasks will be deleted.',
                      confirmLabel: 'Delete');
                  if (!context.mounted || !ok) return;
                  onDeleteTaskList(taskList.id);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        if (tasks.isNotEmpty) ...[
          const SizedBox(height: 4),
          LinearProgressIndicator(value: done / tasks.length),
        ],
        for (final t in tasks)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: t.isCompleted,
            title: Text(
              t.name,
              style: t.isCompleted
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            secondary: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (action) async {
                if (action == 'rename') {
                  final name = await promptText(context,
                      title: 'Rename task', initialValue: t.name);
                  if (!context.mounted || name == null) return;
                  onRenameTask(t.id, name);
                } else if (action == 'delete') {
                  final ok = await confirmDialog(context,
                      title: 'Delete task?', confirmLabel: 'Delete');
                  if (!context.mounted || !ok) return;
                  onDeleteTask(t.id);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
            onChanged: (v) => onToggleTask(t.id, v ?? false),
          ),
        InlineAddField(label: 'Add task', onSubmit: onAddTask),
      ],
    );
  }
}
