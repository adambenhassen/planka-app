import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/models.dart';
import '../auth/auth_providers.dart';
import '../state/board_state.dart';
import '../state/projects_state.dart';
import 'error_handling.dart';
import 'theme/app_theme.dart';
import 'card_sheet.dart';
import 'widgets/async_retry.dart';
import 'widgets/board_background.dart';
import 'widgets/archive_trash_dialog.dart';
import 'widgets/board_members_dialog.dart';
import 'card_tile.dart';
import 'widgets/confirm_dialog.dart';
import 'widgets/inline_add_field.dart';
import 'widgets/prompt_dialog.dart';

const _columnWidth = 300.0;

/// A board's background: its project's Planka background (gradient or uploaded
/// image) when set, otherwise a deterministic gradient from the board name.
/// Reads the projects list (already loaded when navigating in; absent on a cold
/// deep link, which just yields the deterministic fallback).
BoardBackground boardBackgroundFor(WidgetRef ref, PlankaBoard board) {
  final view = ref.watch(projectsProvider).value;
  PlankaProject? project;
  if (view != null) {
    for (final p in view.projects) {
      if (p.id == board.projectId) {
        project = p;
        break;
      }
    }
  }
  return resolveBoardBackground(
    project,
    view?.backgroundImages ?? const [],
    board.name,
    large: true,
  );
}

/// Client-side card filter: text over name/description, plus label and member
/// selections (all criteria must match).
class BoardFilter {
  const BoardFilter({
    this.query = '',
    this.labelIds = const {},
    this.userIds = const {},
  });
  final String query;
  final Set<String> labelIds;
  final Set<String> userIds;

  bool get isActive =>
      query.isNotEmpty || labelIds.isNotEmpty || userIds.isNotEmpty;

  bool matches(BoardState s, PlankaCard c) {
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      if (!c.name.toLowerCase().contains(q) &&
          !(c.description?.toLowerCase().contains(q) ?? false)) {
        return false;
      }
    }
    if (labelIds.isNotEmpty &&
        !s.labelsOf(c.id).any((l) => labelIds.contains(l.id))) {
      return false;
    }
    if (userIds.isNotEmpty &&
        !s.membersOf(c.id).any((u) => userIds.contains(u.id))) {
      return false;
    }
    return true;
  }
}

class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key, required this.boardId});
  final String boardId;

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  bool _showFilter = false;
  BoardFilter _filter = const BoardFilter();

  String get boardId => widget.boardId;

  Future<void> _onMenu(String action, BoardState state) async {
    final notifier = ref.read(boardProvider(boardId).notifier);
    switch (action) {
      case 'rename':
        final name = await promptText(context,
            title: 'Rename board', initialValue: state.board.name);
        if (!mounted || name == null || name == state.board.name) return;
        guardMutation(context, notifier.renameBoard(name));
      case 'members':
        await showBoardMembersDialog(context, boardId);
      case 'archive':
        await showArchiveTrashDialog(context, boardId);
      case 'delete':
        final ok = await confirmDialog(context,
            title: 'Delete board?',
            message: 'The board and everything on it will be deleted.',
            confirmLabel: 'Delete');
        if (!ok || !mounted) return;
        // Leave the board first — deleting disposes this board's provider.
        final messenger = ScaffoldMessenger.of(context);
        final errorColor = Theme.of(context).colorScheme.error;
        final projects = ref.read(projectsProvider.notifier);
        context.pop();
        projects.deleteBoard(boardId).catchError((Object e) {
          messenger.showSnackBar(SnackBar(
              content: Text('$e'), backgroundColor: errorColor));
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(boardProvider(boardId));
    final state = board.value;
    final b = state?.board;
    return Scaffold(
      // Let the board background run behind the app bar; like the web
      // client, the bar is just a subtle dark overlay on the photo — any
      // tint color would clash with the image behind it.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(b?.name ?? 'Board'),
        backgroundColor:
            b == null ? null : Colors.black.withValues(alpha: 0.12),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: b == null ? null : Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showFilter || _filter.isActive
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
            tooltip: 'Filter cards',
            onPressed: () => setState(() {
              _showFilter = !_showFilter;
              if (!_showFilter) _filter = const BoardFilter();
            }),
          ),
          if (state != null)
            PopupMenuButton<String>(
              onSelected: (action) => _onMenu(action, state),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename board')),
                PopupMenuItem(value: 'members', child: Text('Members')),
                PopupMenuItem(
                    value: 'archive', child: Text('Archive & trash')),
                PopupMenuItem(value: 'delete', child: Text('Delete board')),
              ],
            ),
        ],
      ),
      body: asyncRetry(
        board,
        () => ref.invalidate(boardProvider(boardId)),
        (state) => _BoardBody(
          boardId: boardId,
          state: state,
          filter: _filter,
          filterBar: !_showFilter
              ? null
              : _FilterBar(
                  state: state,
                  filter: _filter,
                  onChanged: (f) => setState(() => _filter = f),
                ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.state,
    required this.filter,
    required this.onChanged,
  });
  final BoardState state;
  final BoardFilter filter;
  final ValueChanged<BoardFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search cards…',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (q) => onChanged(BoardFilter(
                  query: q.trim(),
                  labelIds: filter.labelIds,
                  userIds: filter.userIds)),
            ),
            if (state.labels.isNotEmpty || state.users.isNotEmpty)
              const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final l in state.labels)
                  FilterChip(
                    label: Text(l.name ?? l.color),
                    selected: filter.labelIds.contains(l.id),
                    onSelected: (v) {
                      final ids = {...filter.labelIds};
                      v ? ids.add(l.id) : ids.remove(l.id);
                      onChanged(BoardFilter(
                          query: filter.query,
                          labelIds: ids,
                          userIds: filter.userIds));
                    },
                  ),
                for (final u in state.users.where((u) => state.boardMemberships
                    .any((m) => m.userId == u.id)))
                  FilterChip(
                    avatar: const Icon(Icons.person_outline, size: 16),
                    label: Text(u.name),
                    selected: filter.userIds.contains(u.id),
                    onSelected: (v) {
                      final ids = {...filter.userIds};
                      v ? ids.add(u.id) : ids.remove(u.id);
                      onChanged(BoardFilter(
                          query: filter.query,
                          labelIds: filter.labelIds,
                          userIds: ids));
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardBody extends ConsumerStatefulWidget {
  const _BoardBody({
    required this.boardId,
    required this.state,
    required this.filter,
    required this.filterBar,
  });
  final String boardId;
  final BoardState state;
  final BoardFilter filter;
  final Widget? filterBar;

  @override
  ConsumerState<_BoardBody> createState() => _BoardBodyState();
}

class _BoardBodyState extends ConsumerState<_BoardBody> {
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(boardProvider(widget.boardId).notifier);
    final columns = widget.state.columns;
    final token = ref.watch(currentAccountProvider)?.token;
    final background = boardBackgroundFor(ref, widget.state.board);
    // A photo needs a stronger scrim than a gradient to keep list text legible.
    final scrim = background.imageUrl != null
        ? Colors.black.withValues(alpha: 0.22)
        : context.tokens.boardScrim;
    return Stack(
      children: [
        Positioned.fill(
          child: BoardBackgroundView(background: background, token: token),
        ),
        Positioned.fill(child: ColoredBox(color: scrim)),
        // extendBodyBehindAppBar puts the app bar height into the top
        // padding; SafeArea keeps the lists below the bar while the
        // background above still shows through it.
        SafeArea(
            child: Column(
          children: [
            _ConnectionBanner(boardId: widget.boardId),
            if (widget.filterBar != null) widget.filterBar!,
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: columns.length + 1,
                itemBuilder: (context, i) => i == columns.length
                    // Same translucent surface as the list columns — a bare
                    // text button is illegible over photo backgrounds.
                    ? Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: _columnWidth,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: context.tokens.listSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InlineAddField(
                            label: 'Add list',
                            hintText: 'List name',
                            onSubmit: (name) => guardMutation(
                                context, notifier.createList(name)),
                          ),
                        ),
                      )
                    : _ListColumn(
                        list: columns[i],
                        state: widget.state,
                        notifier: notifier,
                        filter: widget.filter,
                      ),
              ),
            ),
          ],
        )),
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
    required this.filter,
  });

  final PlankaList list;
  final BoardState state;
  final BoardNotifier notifier;
  final BoardFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final cards = filter.isActive
        ? state.cardsOf(list.id).where((c) => filter.matches(state, c)).toList()
        : state.cardsOf(list.id);
    // Top-align inside the full-height list slot so a short list wraps its
    // content and the board background shows below it (Trello behavior),
    // instead of the list surface stretching to the bottom.
    return SizedBox(
      width: _columnWidth + 8,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        list.name ?? '',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${cards.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      padding: EdgeInsets.zero,
                      style: const ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      onSelected: (action) async {
                        if (action == 'rename') {
                          final name = await promptText(context,
                              title: 'Rename list', initialValue: list.name);
                          if (!context.mounted) return;
                          if (name != null && name != list.name) {
                            guardMutation(
                                context, notifier.renameList(list.id, name));
                          }
                        } else if (action == 'sort') {
                          final choice = await _pickSort(context);
                          if (!context.mounted || choice == null) return;
                          guardMutation(
                              context,
                              notifier.sortList(list.id,
                                  fieldName: choice.$1, order: choice.$2));
                        } else if (action == 'delete') {
                          final ok = await confirmDialog(context,
                              title: 'Delete list?',
                              message:
                                  'The list and all its cards will be deleted.',
                              confirmLabel: 'Delete');
                          if (!context.mounted) return;
                          if (ok) {
                            guardMutation(context, notifier.deleteList(list.id));
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'sort', child: Text('Sort by…')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 4),
                  children: [
                    _CardDropTarget(
                      listId: list.id,
                      beforeCard: null,
                      afterCard: cards.firstOrNull,
                      notifier: notifier,
                    ),
                    for (var i = 0; i < cards.length; i++) ...[
                      _DraggableCard(
                        card: cards[i],
                        state: state,
                        notifier: notifier,
                      ),
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
        ),
      ),
    );
  }
}

/// Shows a field/order picker for list sorting. Returns null if dismissed.
Future<(String, String?)?> _pickSort(BuildContext context) =>
    showDialog<(String, String?)>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Sort by'),
        children: [
          for (final field in const [
            ('name', 'Name'),
            ('dueDate', 'Due date'),
            ('createdAt', 'Created date'),
          ])
            for (final order in const [('asc', 'ascending'), ('desc', 'descending')])
              SimpleDialogOption(
                onPressed: () =>
                    Navigator.pop(ctx, (field.$1, order.$1)),
                child: Text('${field.$2} (${order.$2})'),
              ),
        ],
      ),
    );

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
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary),
              )
            : null,
      ),
    );
  }
}
