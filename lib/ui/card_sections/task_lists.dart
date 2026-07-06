import 'package:flutter/material.dart';

import '../../api/models.dart';

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
        _InlineAddField(hint: 'Add checklist', onSubmit: onAddTaskList),
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
        _InlineAddField(hint: 'Add task', onSubmit: onAddTask),
      ],
    );
  }
}

class _InlineAddField extends StatefulWidget {
  const _InlineAddField({required this.hint, required this.onSubmit});
  final String hint;
  final ValueChanged<String> onSubmit;

  @override
  State<_InlineAddField> createState() => _InlineAddFieldState();
}

class _InlineAddFieldState extends State<_InlineAddField> {
  bool _editing = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    setState(() => _editing = false);
    if (text.isEmpty) return;
    _ctrl.clear();
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return TextButton.icon(
        icon: const Icon(Icons.add, size: 18),
        label: Text(widget.hint),
        onPressed: () => setState(() => _editing = true),
      );
    }
    return TextField(
      controller: _ctrl,
      autofocus: true,
      decoration: InputDecoration(
        hintText: widget.hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onSubmitted: (_) => _submit(),
      onTapOutside: (_) => _submit(),
    );
  }
}
