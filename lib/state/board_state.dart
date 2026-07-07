import 'package:flutter/foundation.dart';
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
  final List<PlankaCardLabel> cardLabels;
  final List<PlankaCardMembership> cardMemberships;
  final List<PlankaBoardMembership> boardMemberships;
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
      lists
          .where((l) =>
              l.type == PlankaListType.active ||
              l.type == PlankaListType.closed)
          .toList();

  List<PlankaCard> cardsOf(String listId) =>
      cards.values.where((c) => c.listId == listId).toList()
        ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

  /// The labels attached to a card (cardLabels junction joined to labels).
  List<PlankaLabel> labelsOf(String cardId) => cardLabels
      .where((cl) => cl.cardId == cardId)
      .map((cl) => labels.where((l) => l.id == cl.labelId).firstOrNull)
      .nonNulls
      .toList();

  /// The users assigned to a card (cardMemberships junction joined to users).
  List<PlankaUser> membersOf(String cardId) => cardMemberships
      .where((m) => m.cardId == cardId)
      .map((m) => users.where((u) => u.id == m.userId).firstOrNull)
      .nonNulls
      .toList();

  List<PlankaTaskList> taskListsOf(String cardId) =>
      taskLists.where((t) => t.cardId == cardId).toList()
        ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

  /// All tasks across a card's task lists.
  List<PlankaTask> tasksOfCard(String cardId) {
    final ids =
        taskLists.where((t) => t.cardId == cardId).map((t) => t.id).toSet();
    return tasks.where((t) => ids.contains(t.taskListId)).toList();
  }

  List<PlankaAttachment> attachmentsOf(String cardId) =>
      attachments.where((a) => a.cardId == cardId).toList();

  List<PlankaComment> commentsOf(String cardId) =>
      comments.where((c) => c.cardId == cardId).toList()
        ..sort((a, b) => (a.createdAt ?? DateTime(0))
            .compareTo(b.createdAt ?? DateTime(0)));

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
    List<PlankaCardLabel>? cardLabels,
    List<PlankaCardMembership>? cardMemberships,
    List<PlankaBoardMembership>? boardMemberships,
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
              s.cardMemberships, PlankaCardMembership.fromJson(item), (m) => m.id));
    case 'cardMembershipDelete':
      return s.copyWith(
          cardMemberships:
              s.cardMemberships.where((m) => m.id != id).toList());
    case 'cardLabelCreate':
      return s.copyWith(
          cardLabels:
              _upsert(s.cardLabels, PlankaCardLabel.fromJson(item), (c) => c.id));
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
              PlankaBoardMembership.fromJson(item), (m) => m.id));
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
  BoardNotifier(this.boardId);

  /// The board id this notifier manages.
  final String boardId;

  PlankaRepo get _repo => PlankaRepo(ref.read(apiProvider));
  PlankaSocket? _socket;

  @override
  Future<BoardState> build() async {
    final env = await _repo.board(boardId);
    final account = ref.read(currentAccountProvider)!;
    final socket = PlankaSocket(account.serverUrl, account.token);
    _socket = socket;
    ref.onDispose(socket.dispose);
    // A stream/subscribe error only degrades realtime — the REST-loaded board
    // is still valid, hard disconnects surface via _ConnectionBanner, and a
    // reconnect re-subscribes (onConnect) then refetches. So we log rather than
    // alarm the user.
    // ponytail: a subscribe-ack failure without a disconnect leaves realtime
    // silently stale until the board is reopened; add a "live updates
    // unavailable" banner state if that proves user-visible.
    socket.events.listen(_onEvent,
        onError: (Object e) => debugPrint('board socket error: $e'));
    socket.connected.listen((c) {
      // On reconnect the socket re-subscribes itself; refetch to fill the gap.
      if (c) _refetch();
    });
    await socket.connect();
    await socket.subscribeBoard(boardId);
    return BoardState.fromEnvelope(env);
  }

  void _onEvent(SocketEvent event) {
    final s = state.value;
    if (s != null) state = AsyncData(applyEvent(s, event));
  }

  Stream<bool>? get socketConnected => _socket?.connected;

  Future<void> _optimistic(
      BoardState next, Future<Envelope> Function() call) async {
    state = AsyncData(next);
    try {
      await call();
    } on ApiException {
      // Don't restore a snapshot — concurrent socket events/actions may have
      // landed since. The server is the source of truth: refetch.
      await _refetch();
      rethrow;
    }
  }

  Future<void> _refetch() async {
    try {
      state = AsyncData(BoardState.fromEnvelope(await _repo.board(boardId)));
    } on ApiException {
      // Keep current state; next socket event or user retry will heal it.
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

  /// Awaits a create request and folds the parsed server row into the current
  /// state via [upsert] — but only if the board is still loaded. Shared
  /// reconcile tail for every create* operation.
  Future<void> _createInto<T>(
    Future<Envelope> create,
    T Function(Map<String, dynamic>) fromJson,
    BoardState Function(BoardState, T) upsert,
  ) async {
    final env = await create;
    final cur = state.value;
    if (cur != null) state = AsyncData(upsert(cur, fromJson(env.item)));
  }

  Future<void> createCard(String listId, String name) async {
    final s = state.value;
    if (s == null) return;
    final last = s.cardsOf(listId).lastOrNull?.position;
    await _createInto(
      _repo.createCard(listId,
          name: name, position: last == null ? kPositionGap : last + kPositionGap),
      PlankaCard.fromJson,
      (b, c) => b.copyWith(cards: {...b.cards, c.id: c}),
    );
  }

  Future<void> renameCard(String cardId, String name) =>
      _patchCard(cardId, {'name': name});

  Future<void> deleteCard(String cardId) async {
    final s = state.value;
    if (s == null) return;
    await _optimistic(
      s.copyWith(cards: {...s.cards}..remove(cardId)),
      () => _repo.deleteCard(cardId),
    );
  }

  Future<void> archiveCard(String cardId) async {
    final s = state.value;
    final card = s?.cards[cardId];
    if (s == null || card == null) return;
    final archive =
        s.lists.where((l) => l.type == PlankaListType.archive).firstOrNull;
    if (archive == null) return;
    await _optimistic(
      s.copyWith(
          cards: {...s.cards, cardId: _mergeCard(card, {'listId': archive.id})}),
      () => _repo.updateCard(cardId, {'listId': archive.id}),
    );
  }

  Future<void> createList(String name) async {
    final s = state.value;
    if (s == null) return;
    final last = s.lists.lastOrNull?.position;
    await _createInto(
      _repo.createList(boardId,
          name: name, position: last == null ? kPositionGap : last + kPositionGap),
      PlankaList.fromJson,
      (b, l) => b.copyWith(lists: _upsert(b.lists, l, (x) => x.id)),
    );
  }

  /// Optimistically applies a partial card patch and PATCHes it server-side.
  /// Private: callers use the typed setters below rather than raw field maps.
  Future<void> _patchCard(String cardId, Map<String, dynamic> patch) async {
    final s = state.value;
    final card = s?.cards[cardId];
    if (s == null || card == null) return;
    await _optimistic(
      s.copyWith(cards: {...s.cards, cardId: _mergeCard(card, patch)}),
      () => _repo.updateCard(cardId, patch),
    );
  }

  Future<void> setDescription(String cardId, String description) =>
      _patchCard(cardId, {'description': description});

  Future<void> setDueDate(String cardId, DateTime? dueDate) =>
      _patchCard(cardId, {'dueDate': dueDate?.toUtc().toIso8601String()});

  Future<void> setDueCompleted(String cardId, bool isDueCompleted) =>
      _patchCard(cardId, {'isDueCompleted': isDueCompleted});

  /// Toggles a card↔junction row (label, member). When [existing] is present it
  /// is dropped optimistically and deleted server-side; otherwise [temp] is
  /// inserted optimistically, created via [add], then reconciled — the temp and
  /// any socket echo matching [sameKey] are replaced by the real server row.
  Future<void> _toggleJunction<T>({
    required T? existing,
    required List<T> Function(BoardState) list,
    required BoardState Function(BoardState, List<T>) withList,
    required String Function(T) id,
    required T temp,
    required Future<Envelope> Function() add,
    required T Function(Map<String, dynamic>) fromJson,
    required bool Function(T real, T candidate) sameKey,
    required Future<Envelope> Function() remove,
  }) async {
    final s = state.value;
    if (s == null) return;
    if (existing != null) {
      await _optimistic(
        withList(s, list(s).where((e) => id(e) != id(existing)).toList()),
        remove,
      );
      return;
    }
    await _optimistic(
      withList(s, [...list(s), temp]),
      () async {
        final env = await add();
        final cur = state.value;
        if (cur != null) {
          final real = fromJson(env.item);
          state = AsyncData(withList(cur, [
            ...list(cur).where((e) => id(e) != id(temp) && !sameKey(real, e)),
            real,
          ]));
        }
        return env;
      },
    );
  }

  Future<void> toggleLabel(String cardId, String labelId) async {
    final existing = state.value?.cardLabels
        .where((cl) => cl.cardId == cardId && cl.labelId == labelId)
        .firstOrNull;
    await _toggleJunction<PlankaCardLabel>(
      existing: existing,
      list: (b) => b.cardLabels,
      withList: (b, l) => b.copyWith(cardLabels: l),
      id: (cl) => cl.id,
      temp: PlankaCardLabel(
          id: 'tmp-$cardId-$labelId', cardId: cardId, labelId: labelId),
      add: () => _repo.addCardLabel(cardId, labelId),
      fromJson: PlankaCardLabel.fromJson,
      sameKey: (real, cl) =>
          cl.cardId == real.cardId && cl.labelId == real.labelId,
      remove: () => _repo.removeCardLabel(cardId, labelId),
    );
  }

  Future<void> toggleMember(String cardId, String userId) async {
    final existing = state.value?.cardMemberships
        .where((m) => m.cardId == cardId && m.userId == userId)
        .firstOrNull;
    await _toggleJunction<PlankaCardMembership>(
      existing: existing,
      list: (b) => b.cardMemberships,
      withList: (b, l) => b.copyWith(cardMemberships: l),
      id: (m) => m.id,
      temp: PlankaCardMembership(
          id: 'tmp-$cardId-$userId', cardId: cardId, userId: userId),
      add: () => _repo.addCardMember(cardId, userId),
      fromJson: PlankaCardMembership.fromJson,
      sameKey: (real, m) => m.cardId == real.cardId && m.userId == real.userId,
      remove: () => _repo.removeCardMember(cardId, userId),
    );
  }

  Future<void> createLabel(String color, {String? name}) async {
    final s = state.value;
    if (s == null) return;
    await _createInto(
      _repo.createLabel(boardId,
          name: name,
          color: color,
          position: positionBetween(s.labels.lastOrNull?.position, null)),
      PlankaLabel.fromJson,
      (b, l) => b.copyWith(labels: _upsert(b.labels, l, (x) => x.id)),
    );
  }

  Future<void> createTaskList(String cardId, String name) async {
    final s = state.value;
    if (s == null) return;
    final last = s.taskLists.where((t) => t.cardId == cardId).lastOrNull;
    await _createInto(
      _repo.createTaskList(cardId,
          name: name, position: positionBetween(last?.position, null)),
      PlankaTaskList.fromJson,
      (b, t) => b.copyWith(taskLists: _upsert(b.taskLists, t, (x) => x.id)),
    );
  }

  Future<void> createTask(String taskListId, String name) async {
    final s = state.value;
    if (s == null) return;
    final last = s.tasks.where((t) => t.taskListId == taskListId).lastOrNull;
    await _createInto(
      _repo.createTask(taskListId,
          name: name, position: positionBetween(last?.position, null)),
      PlankaTask.fromJson,
      (b, t) => b.copyWith(tasks: _upsert(b.tasks, t, (x) => x.id)),
    );
  }

  Future<void> setTaskCompleted(String taskId, bool isCompleted) async {
    final s = state.value;
    final task = s?.tasks.where((t) => t.id == taskId).firstOrNull;
    if (s == null || task == null) return;
    final toggled = PlankaTask.fromJson(
        {...task.toJson(), 'isCompleted': isCompleted});
    await _optimistic(
      s.copyWith(tasks: _upsert(s.tasks, toggled, (t) => t.id)),
      () => _repo.updateTask(taskId, {'isCompleted': isCompleted}),
    );
  }

  Future<void> createComment(String cardId, String text) async {
    if (state.value == null) return;
    await _createInto(
      _repo.createComment(cardId, text: text),
      PlankaComment.fromJson,
      (b, c) => b.copyWith(comments: _upsert(b.comments, c, (x) => x.id)),
    );
  }

  Future<void> deleteComment(String commentId) async {
    final s = state.value;
    if (s == null) return;
    await _optimistic(
      s.copyWith(comments: s.comments.where((c) => c.id != commentId).toList()),
      () => _repo.deleteComment(commentId),
    );
  }

  Future<void> uploadAttachment(String cardId,
      {required String filePath, required String name}) async {
    if (state.value == null) return;
    await _createInto(
      _repo.uploadAttachment(cardId, filePath: filePath, name: name),
      PlankaAttachment.fromJson,
      (b, a) => b.copyWith(attachments: _upsert(b.attachments, a, (x) => x.id)),
    );
  }

  Future<void> deleteAttachment(String attachmentId) async {
    final s = state.value;
    if (s == null) return;
    await _optimistic(
      s.copyWith(
          attachments:
              s.attachments.where((a) => a.id != attachmentId).toList()),
      () => _repo.deleteAttachment(attachmentId),
    );
  }

  Future<void> renameList(String listId, String name) async {
    final s = state.value;
    final list = s?.lists.where((l) => l.id == listId).firstOrNull;
    if (s == null || list == null) return;
    final renamed = PlankaList.fromJson({...list.toJson(), 'name': name});
    await _optimistic(
      s.copyWith(lists: _upsert(s.lists, renamed, (l) => l.id)),
      () => _repo.updateList(listId, {'name': name}),
    );
  }

  Future<void> deleteList(String listId) async {
    final s = state.value;
    if (s == null) return;
    await _optimistic(
      s.copyWith(
        lists: s.lists.where((l) => l.id != listId).toList(),
        cards: {
          for (final c in s.cards.values)
            if (c.listId != listId) c.id: c
        },
      ),
      () => _repo.deleteList(listId),
    );
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
