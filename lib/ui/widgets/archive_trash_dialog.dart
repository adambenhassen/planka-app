import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/board_state.dart';
import '../error_handling.dart';
import 'confirm_dialog.dart';

Future<void> showArchiveTrashDialog(BuildContext context, String boardId) =>
    showDialog(
      context: context,
      builder: (_) => _ArchiveTrashDialog(boardId: boardId),
    );

/// Browses a board's archive and trash lists (not part of the board's live
/// state — fetched on demand), with per-card restore and, in trash, hard
/// delete.
class _ArchiveTrashDialog extends ConsumerStatefulWidget {
  const _ArchiveTrashDialog({required this.boardId});
  final String boardId;

  @override
  ConsumerState<_ArchiveTrashDialog> createState() =>
      _ArchiveTrashDialogState();
}

class _ArchiveTrashDialogState extends ConsumerState<_ArchiveTrashDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  Future<List<PlankaCard>>? _archiveFuture;
  Future<List<PlankaCard>>? _trashFuture;

  BoardNotifier get _notifier =>
      ref.read(boardProvider(widget.boardId).notifier);

  String? _listId(PlankaListType type) => ref
      .read(boardProvider(widget.boardId))
      .value
      ?.lists
      .where((l) => l.type == type)
      .firstOrNull
      ?.id;

  void _refetch(PlankaListType type) {
    final listId = _listId(type);
    final future =
        listId == null ? null : _notifier.fetchEndlessListCards(listId);
    setState(() {
      if (type == PlankaListType.archive) {
        _archiveFuture = future;
      } else {
        _trashFuture = future;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _refetch(PlankaListType.archive);
    _refetch(PlankaListType.trash);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.archiveTrashTitle),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [Tab(text: l10n.archiveTab), Tab(text: l10n.trashTab)],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CardList(
                    future: _archiveFuture,
                    onRestore: (card) => _restore(card, PlankaListType.archive),
                  ),
                  _CardList(
                    future: _trashFuture,
                    onRestore: (card) => _restore(card, PlankaListType.trash),
                    onDelete: _delete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionClose),
        ),
      ],
    );
  }

  /// Awaits [mutation] and refetches [from] only on success — a fetch fired
  /// before the PATCH/DELETE lands would still show the card. Errors surface
  /// like guardMutation's.
  Future<void> _mutateThenRefetch(
      Future<void> mutation, PlankaListType from) async {
    try {
      await mutation;
    } catch (e) {
      if (mounted) showApiError(context, e);
      return;
    }
    if (mounted) _refetch(from);
  }

  Future<void> _restore(PlankaCard card, PlankaListType from) =>
      _mutateThenRefetch(_notifier.restoreCard(card), from);

  Future<void> _delete(PlankaCard card) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDialog(context,
        title: l10n.cardDeleteTitle,
        message: l10n.cardDeleteMessage,
        confirmLabel: l10n.actionDelete);
    if (!confirmed || !mounted) return;
    await _mutateThenRefetch(
        _notifier.deleteCard(card.id), PlankaListType.trash);
  }
}

class _CardList extends StatelessWidget {
  const _CardList({required this.future, required this.onRestore, this.onDelete});
  final Future<List<PlankaCard>>? future;
  final ValueChanged<PlankaCard> onRestore;
  final ValueChanged<PlankaCard>? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (future == null) {
      return Center(child: Text(l10n.archiveTrashNoList));
    }
    return FutureBuilder<List<PlankaCard>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        final cards = snapshot.data ?? const [];
        if (cards.isEmpty) {
          return Center(child: Text(l10n.archiveTrashEmpty));
        }
        return ListView(
          children: [
            for (final card in cards)
              ListTile(
                title: Text(card.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore),
                      tooltip: l10n.actionRestore,
                      onPressed: () => onRestore(card),
                    ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n.actionDelete,
                        onPressed: () => onDelete!(card),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
