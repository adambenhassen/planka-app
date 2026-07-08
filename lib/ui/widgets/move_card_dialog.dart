import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/envelope.dart';
import '../../api/models.dart';
import '../../api/repositories.dart';
import '../../auth/auth_providers.dart';
import '../../state/board_state.dart';
import '../../state/positions.dart';
import '../../state/projects_state.dart';
import '../error_handling.dart';

/// Moves a card to a list on another board — possibly in another project.
/// Cascading pickers: project -> board -> list, the last fetched on demand
/// (the projects envelope doesn't include lists). Resolves `true` if the card
/// left [boardId] for another board, so the caller can also close the card
/// sheet.
Future<bool> showMoveCardDialog(
        BuildContext context, String boardId, String cardId) =>
    showDialog<bool>(
      context: context,
      builder: (_) => _MoveCardDialog(boardId: boardId, cardId: cardId),
    ).then((moved) => moved ?? false);

class _MoveCardDialog extends ConsumerStatefulWidget {
  const _MoveCardDialog({required this.boardId, required this.cardId});
  final String boardId;
  final String cardId;

  @override
  ConsumerState<_MoveCardDialog> createState() => _MoveCardDialogState();
}

class _MoveCardDialogState extends ConsumerState<_MoveCardDialog> {
  String? _projectId;
  String? _targetBoardId;
  String? _targetListId;
  Future<Envelope>? _boardFuture;
  bool _submitting = false;

  void _selectBoard(String? id) {
    setState(() {
      _targetBoardId = id;
      _targetListId = null;
      _boardFuture = id == null
          ? null
          : PlankaRepo(ref.read(apiProvider)).board(id);
    });
  }

  Future<void> _confirm() async {
    final projectId = _projectId;
    final boardId = _targetBoardId;
    final listId = _targetListId;
    if (projectId == null || boardId == null || listId == null) return;
    setState(() => _submitting = true);
    try {
      final env = await _boardFuture!;
      final last = env.included.cards
          .where((c) => c.listId == listId)
          .map((c) => c.position ?? 0)
          .fold<double?>(null, (max, p) => max == null || p > max ? p : max);
      final position = last == null ? kPositionGap : last + kPositionGap;
      final notifier =
          ref.read(boardProvider(widget.boardId).notifier);
      await notifier.moveCardToBoard(widget.cardId,
          boardId: boardId, listId: listId, position: position);
      if (!mounted) return;
      Navigator.pop(context, boardId != widget.boardId);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider).value;

    return AlertDialog(
      title: const Text('Move card'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _projectId,
              decoration: const InputDecoration(labelText: 'Project'),
              items: [
                for (final p in projects?.projects ?? const <PlankaProject>[])
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (id) => setState(() {
                _projectId = id;
                _selectBoard(null);
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _targetBoardId,
              decoration: const InputDecoration(labelText: 'Board'),
              items: [
                for (final b in (projects?.boards ?? const <PlankaBoard>[])
                    .where((b) => b.projectId == _projectId))
                  DropdownMenuItem(value: b.id, child: Text(b.name)),
              ],
              onChanged: _projectId == null ? null : _selectBoard,
            ),
            const SizedBox(height: 12),
            FutureBuilder<Envelope>(
              future: _boardFuture,
              builder: (context, snapshot) {
                if (_targetBoardId == null) {
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'List'),
                    items: const [],
                    onChanged: null,
                  );
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                final lists = snapshot.data!.included.lists.where((l) =>
                    l.type == PlankaListType.active ||
                    l.type == PlankaListType.closed);
                return DropdownButtonFormField<String>(
                  initialValue: _targetListId,
                  decoration: const InputDecoration(labelText: 'List'),
                  items: [
                    for (final l in lists)
                      DropdownMenuItem(value: l.id, child: Text(l.name ?? '')),
                  ],
                  onChanged: (id) => setState(() => _targetListId = id),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _targetListId == null || _submitting ? null : _confirm,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Move'),
        ),
      ],
    );
  }
}
