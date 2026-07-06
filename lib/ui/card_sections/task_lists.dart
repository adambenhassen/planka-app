import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../widgets/inline_add_field.dart';

class CardTaskListsSection extends StatelessWidget {
  const CardTaskListsSection({
    super.key,
    required this.taskLists,
    required this.tasks,
    required this.onToggleTask,
    required this.onAddTask,
    required this.onAddTaskList,
  });

  final List<PlankaTaskList> taskLists;
  final List<PlankaTask> tasks;
  final void Function(String taskId, bool isCompleted) onToggleTask;
  final void Function(String taskListId, String name) onAddTask;
  final ValueChanged<String> onAddTaskList;

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
  });

  final PlankaTaskList taskList;
  final List<PlankaTask> tasks;
  final void Function(String taskId, bool isCompleted) onToggleTask;
  final ValueChanged<String> onAddTask;

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => t.isCompleted).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(taskList.name, style: Theme.of(context).textTheme.titleSmall),
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
            onChanged: (v) => onToggleTask(t.id, v ?? false),
          ),
        InlineAddField(label: 'Add task', onSubmit: onAddTask),
      ],
    );
  }
}

