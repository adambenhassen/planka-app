import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/envelope.dart';
import '../api/models.dart';
import '../api/planka_api.dart';
import '../api/planka_socket.dart';
import '../api/repositories.dart';
import '../auth/auth_providers.dart';
import 'positions.dart';

class BoardState {
  final PlankaBoard board;
  final List<PlankaList> lists; // sorted by position
  final Map<String, PlankaCard> cards;
  final List<PlankaLabel> labels;
  final List<CardLabel> cardLabels;
  final List<CardMembership> cardMemberships;
  final List<BoardMembership> boardMemberships;
  final List<PlankaUser> users;
  final List<PlankaTaskList> taskLists;
  final List<PlankaTask> tasks;
  final List<PlankaAttachment> attachments;
  final List<PlankaComment> comments;

  BoardState({
    required this.board,
    required List<PlankaList> lists,
    required this.cards,
    this.labels = const [],
    this.cardLabels = const [],
    this.cardMemberships = const [],
    this.boardMemberships = const [],
    this.users = const [],
    this.taskLists = const [],
    this.tasks = const [],
    this.attachments = const [],
    this.comments = const [],
  }) : lists = [...lists]
          ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

  /// Kanban columns: user lists only (server also sends archive/trash lists).
  List<PlankaList> get columns =>
      lists.where((l) => l.type == 'active' || l.type == 'closed').toList();

  List<PlankaCard> cardsOf(String listId) =>
      cards.values.where((c) => c.listId == listId).toList()
        ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

  factory BoardState.fromEnvelope(Envelope env) {
    final included = env.included;
    return BoardState(
      board: PlankaBoard.fromJson(env.item),
      lists: included.lists,
      cards: {for (final c in included.cards) c.id: c},
      labels: included.labels,
      cardLabels: included.cardLabels,
      cardMemberships: included.cardMemberships,
      boardMemberships: included.boardMemberships,
      users: included.users,
      taskLists: included.taskLists,
      tasks: included.tasks,
      attachments: included.attachments,
      comments: included.comments,
    );
  }

  BoardState copyWith({
    PlankaBoard? board,
    List<PlankaList>? lists,
    Map<String, PlankaCard>? cards,
    List<PlankaLabel>? labels,
    List<CardLabel>? cardLabels,
    List<CardMembership>? cardMemberships,
    List<BoardMembership>? boardMemberships,
    List<PlankaUser>? users,
    List<PlankaTaskList>? taskLists,
    List<PlankaTask>? tasks,
    List<PlankaAttachment>? attachments,
    List<PlankaComment>? comments,
  }) =>
      BoardState(
        board: board ?? this.board,
        lists: lists ?? this.lists,
        cards: cards ?? this.cards,
        labels: labels ?? this.labels,
        cardLabels: cardLabels ?? this.cardLabels,
        cardMemberships: cardMemberships ?? this.cardMemberships,
        boardMemberships: boardMemberships ?? this.boardMemberships,
        users: users ?? this.users,
        taskLists: taskLists ?? this.taskLists,
        tasks: tasks ?? this.tasks,
        attachments: attachments ?? this.attachments,
        comments: comments ?? this.comments,
      );
}

/// Merge a partial socket payload into an existing card (e.g. `{id, position}`).
PlankaCard _mergeCard(PlankaCard existing, Map<String, dynamic> patch) =>
    PlankaCard.fromJson({...existing.toJson(), ...patch});

List<T> _upsert<T>(List<T> list, T item, String Function(T) idOf) => [
      ...list.where((e) => idOf(e) != idOf(item)),
      item,
    ];

/// Fold one socket event into board state. Pure; exported for tests.
BoardState applyEvent(BoardState s, SocketEvent event) {
  final item = event.data.item;
  final id = item['id'] as String?;
  switch (event.name) {
    case 'boardUpdate':
      return s.copyWith(board: PlankaBoard.fromJson(item));
    case 'listCreate' || 'listUpdate':
      return s.copyWith(
          lists: _upsert(s.lists, PlankaList.fromJson(item), (l) => l.id));
    case 'listDelete':
      return s.copyWith(lists: s.lists.where((l) => l.id != id).toList());
    case 'listClear':
      return s.copyWith(cards: {
        for (final c in s.cards.values)
          if (c.listId != id) c.id: c
      });
    case 'labelCreate' || 'labelUpdate':
      return s.copyWith(
          labels: _upsert(s.labels, PlankaLabel.fromJson(item), (l) => l.id));
    case 'labelDelete':
      return s.copyWith(
        labels: s.labels.where((l) => l.id != id).toList(),
        cardLabels: s.cardLabels.where((cl) => cl.labelId != id).toList(),
      );
    case 'cardCreate':
      final card = PlankaCard.fromJson(item);
      return s.copyWith(cards: {...s.cards, card.id: card});
    case 'cardUpdate':
      if (id == null) return s;
      final existing = s.cards[id];
      final card = existing == null
          ? PlankaCard.fromJson(item)
          : _mergeCard(existing, item);
      return s.copyWith(cards: {...s.cards, id: card});
    case 'cardDelete':
      return s.copyWith(cards: {...s.cards}..remove(id));
    case 'cardsUpdate':
      final updated = {...s.cards};
      for (final raw in event.data.items) {
        final cid = raw['id'] as String?;
        if (cid == null) continue;
        final existing = updated[cid];
        updated[cid] = existing == null
            ? PlankaCard.fromJson(raw)
            : _mergeCard(existing, raw);
      }
      return s.copyWith(cards: updated);
    case 'cardMembershipCreate':
      return s.copyWith(
          cardMemberships: _upsert(
              s.cardMemberships, CardMembership.fromJson(item), (m) => m.id));
    case 'cardMembershipDelete':
      return s.copyWith(
          cardMemberships:
              s.cardMemberships.where((m) => m.id != id).toList());
    case 'cardLabelCreate':
      return s.copyWith(
          cardLabels:
              _upsert(s.cardLabels, CardLabel.fromJson(item), (c) => c.id));
    case 'cardLabelDelete':
      return s.copyWith(
          cardLabels: s.cardLabels.where((c) => c.id != id).toList());
    case 'taskListCreate' || 'taskListUpdate':
      return s.copyWith(
          taskLists: _upsert(
              s.taskLists, PlankaTaskList.fromJson(item), (t) => t.id));
    case 'taskListDelete':
      return s.copyWith(
        taskLists: s.taskLists.where((t) => t.id != id).toList(),
        tasks: s.tasks.where((t) => t.taskListId != id).toList(),
      );
    case 'taskCreate' || 'taskUpdate':
      return s.copyWith(
          tasks: _upsert(s.tasks, PlankaTask.fromJson(item), (t) => t.id));
    case 'taskDelete':
      return s.copyWith(tasks: s.tasks.where((t) => t.id != id).toList());
    case 'attachmentCreate' || 'attachmentUpdate':
      return s.copyWith(
          attachments: _upsert(
              s.attachments, PlankaAttachment.fromJson(item), (a) => a.id));
    case 'attachmentDelete':
      return s.copyWith(
          attachments: s.attachments.where((a) => a.id != id).toList());
    case 'commentCreate' || 'commentUpdate':
      return s.copyWith(
          comments:
              _upsert(s.comments, PlankaComment.fromJson(item), (c) => c.id));
    case 'commentDelete':
      return s.copyWith(
          comments: s.comments.where((c) => c.id != id).toList());
    case 'boardMembershipCreate' || 'boardMembershipUpdate':
      return s.copyWith(
          boardMemberships: _upsert(s.boardMemberships,
              BoardMembership.fromJson(item), (m) => m.id));
    case 'boardMembershipDelete':
      return s.copyWith(
          boardMemberships:
              s.boardMemberships.where((m) => m.id != id).toList());
    case 'userUpdate':
      return s.copyWith(
          users: _upsert(s.users, PlankaUser.fromJson(item), (u) => u.id));
    default:
      return s;
  }
}

final boardProvider = AsyncNotifierProvider.family<BoardNotifier, BoardState,
    String>(BoardNotifier.new);

class BoardNotifier extends AsyncNotifier<BoardState> {
  BoardNotifier(this.arg);

  /// The board id this notifier manages.
  final String arg;

  PlankaRepo get _repo => PlankaRepo(ref.read(apiProvider));
  PlankaSocket? _socket;

  @override
  Future<BoardState> build() async {
    final env = await _repo.board(arg);
    final account = ref.read(currentAccountProvider)!;
    final socket = PlankaSocket(account.serverUrl, account.token);
    _socket = socket;
    ref.onDispose(socket.dispose);
    socket.events.listen(_onEvent, onError: (Object _) {});
    socket.connected.listen((c) async {
      // On reconnect the socket re-subscribes itself; refetch to fill the gap.
      if (c) {
        final fresh = await _repo.board(arg);
        state = AsyncData(BoardState.fromEnvelope(fresh));
      }
    });
    await socket.connect();
    await socket.subscribeBoard(arg);
    return BoardState.fromEnvelope(env);
  }

  void _onEvent(SocketEvent event) {
    final s = state.value;
    if (s != null) state = AsyncData(applyEvent(s, event));
  }

  Stream<bool>? get socketConnected => _socket?.connected;

  Future<void> _optimistic(
      BoardState next, Future<Envelope> Function() call) async {
    final prev = state.value;
    state = AsyncData(next);
    try {
      await call();
    } on ApiException {
      if (prev != null) state = AsyncData(prev);
      rethrow;
    }
  }

  Future<void> moveCard(String cardId, String toListId,
      {String? beforeCardId, String? afterCardId}) async {
    final s = state.value;
    final card = s?.cards[cardId];
    if (s == null || card == null) return;
    double? posOf(String? cid) => cid == null ? null : s.cards[cid]?.position;
    final position = positionBetween(posOf(beforeCardId), posOf(afterCardId));
    final moved = _mergeCard(card, {'listId': toListId, 'position': position});
    await _optimistic(
      s.copyWith(cards: {...s.cards, cardId: moved}),
      () => _repo.updateCard(cardId, {'listId': toListId, 'position': position}),
    );
  }

  Future<void> createCard(String listId, String name) async {
    final s = state.value;
    if (s == null) return;
    final last = s.cardsOf(listId).lastOrNull?.position;
    final env =
        await _repo.createCard(listId, name: name, position: last == null ? kPositionGap : last + kPositionGap);
    final card = PlankaCard.fromJson(env.item);
    final cur = state.value;
    if (cur != null) {
      state = AsyncData(cur.copyWith(cards: {...cur.cards, card.id: card}));
    }
  }

  Future<void> renameCard(String cardId, String name) async {
    final s = state.value;
    final card = s?.cards[cardId];
    if (s == null || card == null) return;
    await _optimistic(
      s.copyWith(cards: {...s.cards, cardId: _mergeCard(card, {'name': name})}),
      () => _repo.updateCard(cardId, {'name': name}),
    );
  }

  Future<void> createList(String name) async {
    final s = state.value;
    if (s == null) return;
    final last = s.lists.lastOrNull?.position;
    final env = await _repo.createList(arg,
        name: name, position: last == null ? kPositionGap : last + kPositionGap);
    final list = PlankaList.fromJson(env.item);
    final cur = state.value;
    if (cur != null) {
      state = AsyncData(
          cur.copyWith(lists: _upsert(cur.lists, list, (l) => l.id)));
    }
  }

  Future<void> moveList(String listId,
      {String? beforeListId, String? afterListId}) async {
    final s = state.value;
    final list = s?.lists.where((l) => l.id == listId).firstOrNull;
    if (s == null || list == null) return;
    double? posOf(String? lid) =>
        s.lists.where((l) => l.id == lid).firstOrNull?.position;
    final position = positionBetween(posOf(beforeListId), posOf(afterListId));
    final movedList = PlankaList.fromJson({...list.toJson(), 'position': position});
    await _optimistic(
      s.copyWith(lists: _upsert(s.lists, movedList, (l) => l.id)),
      () => _repo.updateList(listId, {'position': position}),
    );
  }
}
