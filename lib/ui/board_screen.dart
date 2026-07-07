import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../state/board_state.dart';
import 'error_handling.dart';
import 'theme/app_theme.dart';
import 'card_sheet.dart';
import 'widgets/async_retry.dart';
import 'widgets/card_tile.dart';
import 'widgets/inline_add_field.dart';

const _columnWidth = 300.0;

class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key, required this.boardId});
  final String boardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(boardProvider(boardId));
    final name = board.value?.board.name;
    return Scaffold(
      appBar: AppBar(
        title: Text(name ?? 'Board'),
        backgroundColor: name != null ? boardColor(name) : null,
        foregroundColor: name != null ? Colors.white : null,
      ),
      body: asyncRetry(
        board,
        () => ref.invalidate(boardProvider(boardId)),
        (state) => _BoardBody(boardId: boardId, state: state),
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
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration:
                BoxDecoration(gradient: boardGradient(widget.state.board.name)),
          ),
        ),
        Positioned.fill(child: ColoredBox(color: context.tokens.boardScrim)),
        Column(
          children: [
            _ConnectionBanner(boardId: widget.boardId),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: columns.length + 1,
                itemBuilder: (context, i) => i == columns.length
                    ? InlineAddField(
                        label: 'Add list',
                        hintText: 'List name',
                        columnWidth: _columnWidth,
                        onSubmit: (name) =>
                            guardMutation(context, notifier.createList(name)),
                      )
                    : _ListColumn(
                        list: columns[i],
                        state: widget.state,
                        notifier: notifier,
                      ),
              ),
            ),
          ],
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
    final tokens = context.tokens;
    final cards = state.cardsOf(list.id);
    return Container(
      width: _columnWidth,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: tokens.listSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
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
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
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
          InlineAddField(
            label: 'Add card',
            hintText: 'Card name',
            onSubmit: (name) =>
                guardMutation(context, notifier.createCard(list.id, name)),
          ),
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
      onTap: () => showCardSheet(context, card.boardId, card.id),
    );
    return LongPressDraggable<PlankaCard>(
      data: card,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: _columnWidth - 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: context.tokens.dragShadow,
          ),
          child: tile,
        ),
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
      onAcceptWithDetails: (d) => guardMutation(
        context,
        notifier.moveCard(
          d.data.id,
          listId,
          beforeCardId: beforeCard?.id,
          afterCardId: afterCard?.id,
        ),
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

