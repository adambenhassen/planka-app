import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../state/board_state.dart';
import 'widgets/card_tile.dart';

const _columnWidth = 300.0;

class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key, required this.boardId});
  final String boardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(boardProvider(boardId));
    return Scaffold(
      appBar: AppBar(title: Text(board.value?.board.name ?? 'Board')),
      body: board.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(boardProvider(boardId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (state) => _BoardBody(boardId: boardId, state: state),
      ),
    );
  }
}

class _BoardBody extends ConsumerStatefulWidget {
  const _BoardBody({required this.boardId, required this.state});
  final String boardId;
  final BoardState state;

  @override
  ConsumerState<_BoardBody> createState() => _BoardBodyState();
}

class _BoardBodyState extends ConsumerState<_BoardBody> {
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(boardProvider(widget.boardId).notifier);
    final columns = widget.state.columns;
    return Column(
      children: [
        _ConnectionBanner(boardId: widget.boardId),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            itemCount: columns.length + 1,
            itemBuilder: (context, i) => i == columns.length
                ? _AddListColumn(onSubmit: notifier.createList)
                : _ListColumn(
                    list: columns[i],
                    state: widget.state,
                    notifier: notifier,
                  ),
          ),
        ),
      ],
    );
  }
}

class _ConnectionBanner extends ConsumerWidget {
  const _ConnectionBanner({required this.boardId});
  final String boardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(boardProvider(boardId).notifier);
    return StreamBuilder<bool>(
      stream: notifier.socketConnected,
      initialData: true,
      builder: (context, snap) => snap.data == false
          ? MaterialBanner(
              content: const Text('Reconnecting…'),
              leading: const Icon(Icons.wifi_off),
              actions: const [SizedBox.shrink()],
            )
          : const SizedBox.shrink(),
    );
  }
}

class _ListColumn extends StatelessWidget {
  const _ListColumn({
    required this.list,
    required this.state,
    required this.notifier,
  });

  final PlankaList list;
  final BoardState state;
  final BoardNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = state.cardsOf(list.id);
    return Container(
      width: _columnWidth,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    list.name ?? '',
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${cards.length}',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 4),
              children: [
                _CardDropTarget(
                    listId: list.id, beforeCard: null, afterCard: cards.firstOrNull, notifier: notifier),
                for (var i = 0; i < cards.length; i++) ...[
                  _DraggableCard(
                      card: cards[i], state: state, notifier: notifier),
                  _CardDropTarget(
                    listId: list.id,
                    beforeCard: cards[i],
                    afterCard: i + 1 < cards.length ? cards[i + 1] : null,
                    notifier: notifier,
                  ),
                ],
              ],
            ),
          ),
          _AddCardField(onSubmit: (name) => notifier.createCard(list.id, name)),
        ],
      ),
    );
  }
}

class _DraggableCard extends StatelessWidget {
  const _DraggableCard({
    required this.card,
    required this.state,
    required this.notifier,
  });

  final PlankaCard card;
  final BoardState state;
  final BoardNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final tile = CardTile(
      card: card,
      state: state,
      onTap: () {
        // Card detail sheet lands in Task 11.
      },
    );
    return LongPressDraggable<PlankaCard>(
      data: card,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: _columnWidth - 16, child: tile),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: tile),
      child: tile,
    );
  }
}

/// Drop zone between two cards (or at list edges).
class _CardDropTarget extends StatelessWidget {
  const _CardDropTarget({
    required this.listId,
    required this.beforeCard,
    required this.afterCard,
    required this.notifier,
  });

  final String listId;
  final PlankaCard? beforeCard;
  final PlankaCard? afterCard;
  final BoardNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<PlankaCard>(
      key: ValueKey('drop-$listId-${beforeCard?.id}-${afterCard?.id}'),
      onWillAcceptWithDetails: (d) =>
          d.data.id != beforeCard?.id && d.data.id != afterCard?.id,
      onAcceptWithDetails: (d) => notifier.moveCard(
        d.data.id,
        listId,
        beforeCardId: beforeCard?.id,
        afterCardId: afterCard?.id,
      ),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: candidates.isNotEmpty ? 56 : 8,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: candidates.isNotEmpty
            ? BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary),
              )
            : null,
      ),
    );
  }
}

class _AddCardField extends StatefulWidget {
  const _AddCardField({required this.onSubmit});
  final Future<void> Function(String name) onSubmit;

  @override
  State<_AddCardField> createState() => _AddCardFieldState();
}

class _AddCardFieldState extends State<_AddCardField> {
  bool _editing = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      setState(() => _editing = false);
      return;
    }
    _ctrl.clear();
    setState(() => _editing = false);
    try {
      await widget.onSubmit(name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return TextButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add card'),
        onPressed: () => setState(() => _editing = true),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Card name',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onSubmitted: (_) => _submit(),
        onTapOutside: (_) => _submit(),
      ),
    );
  }
}

class _AddListColumn extends StatefulWidget {
  const _AddListColumn({required this.onSubmit});
  final Future<void> Function(String name) onSubmit;

  @override
  State<_AddListColumn> createState() => _AddListColumnState();
}

class _AddListColumnState extends State<_AddListColumn> {
  bool _editing = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _ctrl.text.trim();
    setState(() => _editing = false);
    if (name.isEmpty) return;
    _ctrl.clear();
    try {
      await widget.onSubmit(name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _columnWidth,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.topCenter,
      child: _editing
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'List name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _submit(),
                onTapOutside: (_) => _submit(),
              ),
            )
          : TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add list'),
              onPressed: () => setState(() => _editing = true),
            ),
    );
  }
}
