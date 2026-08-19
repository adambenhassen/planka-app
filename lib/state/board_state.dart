import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/envelope.dart';
import '../api/models.dart';
import '../api/planka_api.dart';
import '../api/planka_socket.dart';
import '../api/repositories.dart';
import '../auth/auth_providers.dart';
import 'envelope_cache.dart';
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
  final List<PlankaCustomFieldGroup> customFieldGroups;

  /// Fields of both kinds of group: those keyed by a board/card group come from
  /// the board response, those keyed by a base group from the project response.
  final List<PlankaCustomField> customFields;
  final List<PlankaCustomFieldValue> customFieldValues;
  final List<PlankaBaseCustomFieldGroup> baseCustomFieldGroups;

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
    this.customFieldGroups = const [],
    this.customFields = const [],
    this.customFieldValues = const [],
    this.baseCustomFieldGroups = const [],
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

  /// The custom field groups a card shows: the board's groups first, then the
  /// card's own, each in the server's position order — the order the Planka
  /// web client renders them in. A group that resolved to neither a name nor
  /// any fields is left out: that is an instantiated group whose project could
  /// not be read, and all it can render is an untitled empty block.
  List<PlankaCustomFieldGroup> customFieldGroupsOf(String cardId) {
    bool resolved(PlankaCustomFieldGroup g) =>
        customFieldGroupName(g).isNotEmpty || customFieldsOf(g).isNotEmpty;
    List<PlankaCustomFieldGroup> sorted(
            bool Function(PlankaCustomFieldGroup) test) =>
        customFieldGroups.where(test).where(resolved).toList()
          ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
    return [
      ...sorted((g) => g.boardId == board.id),
      ...sorted((g) => g.cardId == cardId),
    ];
  }

  /// A group's display name. A group instantiated from a project base group
  /// carries no name of its own and shows the base group's.
  String customFieldGroupName(PlankaCustomFieldGroup group) =>
      group.name ??
      baseCustomFieldGroups
          .where((b) => b.id == group.baseCustomFieldGroupId)
          .firstOrNull
          ?.name ??
      '';

  /// A group's fields in position order. An instantiated group shows the
  /// fields of the base group it was built from, not fields of its own.
  List<PlankaCustomField> customFieldsOf(PlankaCustomFieldGroup group) {
    final baseId = group.baseCustomFieldGroupId;
    return customFields
        .where((f) => baseId == null
            ? f.customFieldGroupId == group.id
            : f.baseCustomFieldGroupId == baseId)
        .toList()
      ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
  }

  /// The card's value for a (group, field) pair, or null when none is set.
  PlankaCustomFieldValue? customFieldValueOf(
          String cardId, String groupId, String fieldId) =>
      customFieldValues
          .where((v) =>
              v.cardId == cardId &&
              v.customFieldGroupId == groupId &&
              v.customFieldId == fieldId)
          .firstOrNull;

  /// The (field, value) pairs shown on the card tile: fields flagged
  /// `showOnFrontOfCard` that this card actually holds a value for.
  List<(PlankaCustomField, PlankaCustomFieldValue)> frontOfCardCustomFieldsOf(
          String cardId) =>
      [
        for (final group in customFieldGroupsOf(cardId))
          for (final field in customFieldsOf(group))
            if (field.showOnFrontOfCard == true)
              if (customFieldValueOf(cardId, group.id, field.id)
                  case final value?)
                (field, value),
      ];

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
      customFieldGroups: included.customFieldGroups,
      customFields: included.customFields,
      customFieldValues: included.customFieldValues,
    );
  }

  /// True while some group was instantiated from a base group this state holds
  /// no template for — its name and fields still have to come from the project.
  bool get needsBaseCustomFields => customFieldGroups.any((g) =>
      g.baseCustomFieldGroupId != null &&
      !baseCustomFieldGroups.any((b) => b.id == g.baseCustomFieldGroupId));

  /// Folds a project response in, supplying what the board response omits for
  /// groups instantiated from a base group: the base groups themselves (for
  /// the display name) and their fields. Idempotent — a group arriving over the
  /// socket makes this run again on a state that already holds base fields.
  BoardState withBaseCustomFields(Envelope projectEnv) {
    var fields = customFields;
    for (final f in projectEnv.included.customFields) {
      fields = _upsert(fields, f, (x) => x.id);
    }
    return copyWith(
      customFields: fields,
      baseCustomFieldGroups: projectEnv.included.baseCustomFieldGroups,
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
    List<PlankaCustomFieldGroup>? customFieldGroups,
    List<PlankaCustomField>? customFields,
    List<PlankaCustomFieldValue>? customFieldValues,
    List<PlankaBaseCustomFieldGroup>? baseCustomFieldGroups,
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
        customFieldGroups: customFieldGroups ?? this.customFieldGroups,
        customFields: customFields ?? this.customFields,
        customFieldValues: customFieldValues ?? this.customFieldValues,
        baseCustomFieldGroups:
            baseCustomFieldGroups ?? this.baseCustomFieldGroups,
      );
}

/// Merge a partial socket payload into an existing card (e.g. `{id, position}`).
PlankaCard _mergeCard(PlankaCard existing, Map<String, dynamic> patch) =>
    PlankaCard.fromJson({...existing.toJson(), ...patch});

/// Replaces the item with a matching id in place (preserving list order), or
/// appends it when absent. In-place replacement matters for collections that
/// aren't re-sorted on render (labels, tasks) — an update must not reorder them.
List<T> _upsert<T>(List<T> list, T item, String Function(T) idOf) {
  final i = list.indexWhere((e) => idOf(e) == idOf(item));
  if (i < 0) return [...list, item];
  final next = [...list];
  next[i] = item;
  return next;
}

/// Replaces the row holding the same card's value for the same field, matched
/// on the (card, group, field) key the server addresses a value by rather than
/// on its id — an optimistic write holds a placeholder id until the server
/// answers, and the socket echo of that same write carries the real one.
List<PlankaCustomFieldValue> upsertCustomFieldValue(
    List<PlankaCustomFieldValue> list, PlankaCustomFieldValue value) {
  final i = list.indexWhere((v) =>
      v.id == value.id ||
      (v.cardId == value.cardId &&
          v.customFieldGroupId == value.customFieldGroupId &&
          v.customFieldId == value.customFieldId));
  if (i < 0) return [...list, value];
  final next = [...list];
  next[i] = value;
  return next;
}

/// Merges a socket payload into the row it names, or parses it whole when that
/// row is unknown. Repositioning a group or field broadcasts `{id, position}`
/// for every sibling it shifted, so a partial payload must not blank the rest.
T _mergeById<T>(T? existing, Map<String, dynamic> item,
        Map<String, dynamic> Function(T) toJson,
        T Function(Map<String, dynamic>) fromJson) =>
    fromJson(existing == null ? item : {...toJson(existing), ...item});

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
    case 'customFieldGroupCreate' || 'customFieldGroupUpdate':
      if (id == null) return s;
      final group = _mergeById(
          s.customFieldGroups.where((g) => g.id == id).firstOrNull,
          item,
          (PlankaCustomFieldGroup g) => g.toJson(),
          PlankaCustomFieldGroup.fromJson);
      return s.copyWith(
          customFieldGroups: _upsert(s.customFieldGroups, group, (g) => g.id));
    case 'customFieldGroupDelete':
      return s.copyWith(
        customFieldGroups:
            s.customFieldGroups.where((g) => g.id != id).toList(),
        customFields:
            s.customFields.where((f) => f.customFieldGroupId != id).toList(),
        customFieldValues: s.customFieldValues
            .where((v) => v.customFieldGroupId != id)
            .toList(),
      );
    case 'customFieldCreate' || 'customFieldUpdate':
      if (id == null) return s;
      final field = _mergeById(
          s.customFields.where((f) => f.id == id).firstOrNull,
          item,
          (PlankaCustomField f) => f.toJson(),
          PlankaCustomField.fromJson);
      return s.copyWith(
          customFields: _upsert(s.customFields, field, (f) => f.id));
    case 'customFieldDelete':
      return s.copyWith(
        customFields: s.customFields.where((f) => f.id != id).toList(),
        customFieldValues:
            s.customFieldValues.where((v) => v.customFieldId != id).toList(),
      );
    case 'customFieldValueUpdate':
      return s.copyWith(
          customFieldValues: upsertCustomFieldValue(
              s.customFieldValues, PlankaCustomFieldValue.fromJson(item)));
    case 'customFieldValueDelete':
      // Matched on the key as well as the id: a value the app created moments
      // ago may still be held under its placeholder id.
      return s.copyWith(
          customFieldValues: s.customFieldValues
              .where((v) =>
                  v.id != id &&
                  !(v.cardId == item['cardId'] &&
                      v.customFieldGroupId == item['customFieldGroupId'] &&
                      v.customFieldId == item['customFieldId']))
              .toList());
    default:
      return s;
  }
}

/// A card's activity feed, fetched on demand when its section is shown.
/// ponytail: no actionCreate socket wiring — the feed refetches each time the
/// card sheet opens (autoDispose); wire the socket event if staleness bites.
final cardActionsProvider = FutureProvider.autoDispose
    .family<List<PlankaAction>, String>((ref, cardId) async {
  final env = await PlankaRepo(ref.watch(apiProvider)).cardActions(cardId);
  return env.items.map(PlankaAction.fromJson).toList();
});

/// All server users, for the add-board-member picker. The endpoint is
/// admin/project-owner only; non-admins get a 403 the UI surfaces as a hint.
final allUsersProvider = FutureProvider.autoDispose<List<PlankaUser>>(
    (ref) async {
  final env = await PlankaRepo(ref.watch(apiProvider)).users();
  return env.items.map(PlankaUser.fromJson).toList();
});

final boardProvider = AsyncNotifierProvider.family<BoardNotifier, BoardState,
    String>(BoardNotifier.new);

class BoardNotifier extends AsyncNotifier<BoardState> {
  BoardNotifier(this.boardId);

  /// The board id this notifier manages.
  final String boardId;

  PlankaRepo get _repo => PlankaRepo(ref.read(apiProvider));
  PlankaSocket? _socket;

  /// Loads the board, serving the last good copy when the network is down
  /// (offline read cache); the socket reconnect refetch heals it once we're
  /// back online. Exported so tests can exercise the load without a socket.
  Future<BoardState> load() async {
    final account = ref.read(currentAccountProvider)!;
    final env = await ref.read(envelopeCacheProvider).fetchOrCached(
        '${account.id}-board-$boardId', () => _repo.board(boardId));
    return _withBaseCustomFields(BoardState.fromEnvelope(env));
  }

  /// A custom field group instantiated from a project base group takes its name
  /// and fields from that template, which the board response omits — so fetch
  /// the project, but only for a board that actually has such a group.
  Future<BoardState> _withBaseCustomFields(BoardState s) async {
    if (!s.needsBaseCustomFields) return s;
    final env = await _projectEnvelope(s.board.projectId);
    return env == null ? s : s.withBaseCustomFields(env);
  }

  /// The project response, or null when it cannot be read.
  Future<Envelope?> _projectEnvelope(String projectId) async {
    final account = ref.read(currentAccountProvider);
    if (account == null) return null;
    try {
      return await ref.read(envelopeCacheProvider).fetchOrCached(
          '${account.id}-project-$projectId', () => _repo.project(projectId));
    } on ApiException catch (e) {
      // Reachable offline on the first open after an upgrade: the board
      // envelope is cached, the project one never was. The board still loads;
      // only the instantiated groups lose their name and fields, and
      // customFieldGroupsOf then leaves them out rather than rendering an
      // untitled empty block. Log it — otherwise "my base group shows nothing"
      // arrives with nothing to debug from.
      debugPrint('board $boardId: base custom fields unavailable: $e');
      return null;
    }
  }

  /// Holds the fetch below to one at a time, however many events arrive while
  /// it is in flight — a group create is usually followed by its fields.
  bool _fillingBaseCustomFields = false;

  /// Same fetch as [_withBaseCustomFields], for a group instantiated while the
  /// board is open — it arrives over the socket with neither its name nor its
  /// fields. Folded into whatever state is current when the project answers, so
  /// events landing meanwhile are not overwritten.
  Future<void> _fillBaseCustomFields() async {
    if (_fillingBaseCustomFields) return;
    _fillingBaseCustomFields = true;
    try {
      final projectId = state.value?.board.projectId;
      if (projectId == null) return;
      final env = await _projectEnvelope(projectId);
      final cur = state.value;
      if (env != null && cur != null) {
        state = AsyncData(cur.withBaseCustomFields(env));
      }
    } finally {
      _fillingBaseCustomFields = false;
    }
  }

  @override
  Future<BoardState> build() async {
    final account = ref.read(currentAccountProvider)!;
    final loaded = await load();
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
    socket.events.listen(applySocketEvent,
        onError: (Object e) => debugPrint('board socket error: $e'));
    socket.connected.listen((c) {
      // On reconnect the socket re-subscribes itself; refetch to fill the gap.
      if (c) _refetch();
    });
    await socket.connect();
    await socket.subscribeBoard(boardId);
    return loaded;
  }

  /// Applies one server-pushed event to the board. Public so tests can drive
  /// realtime without a server behind the socket.
  void applySocketEvent(SocketEvent event) {
    // Activity lives in its own provider; a new action just invalidates the
    // affected card's feed so an open sheet refreshes live.
    if (event.name == 'actionCreate') {
      final cardId = event.data.item['cardId'] as String?;
      if (cardId != null) ref.invalidate(cardActionsProvider(cardId));
    }
    final s = state.value;
    if (s == null) return;
    final next = applyEvent(s, event);
    state = AsyncData(next);
    // A group instantiated from a base group is pushed without the name and
    // fields it borrows, so it needs the project the board response omits.
    if (next.needsBaseCustomFields) unawaited(_fillBaseCustomFields());
  }

  Stream<bool>? get socketConnected => _socket?.connected;

  Future<void> _optimistic(
      BoardState next, Future<Envelope> Function() call) async {
    state = AsyncData(next);
    try {
      await call();
    } catch (_) {
      // Any failure — a rejected request (ApiException) or a parse/decode error
      // on an unexpected response — leaves the optimistic state unconfirmed.
      // Don't restore a snapshot (concurrent socket events/actions may have
      // landed since); the server is the source of truth, so refetch. Rethrow
      // so the caller's guardMutation still surfaces the error.
      await _refetch();
      rethrow;
    }
  }

  Future<void> _refetch() async {
    try {
      final env = await _repo.board(boardId);
      final account = ref.read(currentAccountProvider);
      if (account != null) {
        await ref
            .read(envelopeCacheProvider)
            .put('${account.id}-board-$boardId', env);
      }
      state = AsyncData(await _withBaseCustomFields(BoardState.fromEnvelope(env)));
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

  /// Duplicates a card server-side (copies tasks, labels, members) and folds
  /// the new card into state, placed right after the original.
  Future<void> duplicateCard(String cardId) async {
    final card = state.value?.cards[cardId];
    if (card == null) return;
    await _createInto(
      _repo.duplicateCard(cardId,
          position: (card.position ?? 0) + kPositionGap),
      PlankaCard.fromJson,
      (b, c) => b.copyWith(cards: {...b.cards, c.id: c}),
    );
  }

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

  Future<void> moveCardToTrash(String cardId) async {
    final s = state.value;
    final card = s?.cards[cardId];
    if (s == null || card == null) return;
    final trash =
        s.lists.where((l) => l.type == PlankaListType.trash).firstOrNull;
    if (trash == null) return;
    await _optimistic(
      s.copyWith(
          cards: {...s.cards, cardId: _mergeCard(card, {'listId': trash.id})}),
      () => _repo.updateCard(cardId, {'listId': trash.id}),
    );
  }

  /// Fetches the cards of an archive/trash list directly (they aren't part of
  /// the board's socket-synced state), for the archive/trash browsing dialog.
  Future<List<PlankaCard>> fetchEndlessListCards(String listId) async {
    final env = await _repo.cardsOfList(listId);
    return env.items.map(PlankaCard.fromJson).toList();
  }

  /// Restores an archived/trashed card onto the board: back to [card.prevListId]
  /// if that list is still an active/closed list here, else the first active
  /// list. Appended to the end of the target list.
  Future<void> restoreCard(PlankaCard card) async {
    final s = state.value;
    if (s == null) return;
    final columns = s.columns;
    final prev = card.prevListId == null
        ? null
        : columns.where((l) => l.id == card.prevListId).firstOrNull;
    final target = prev ??
        s.lists.where((l) => l.type == PlankaListType.active).firstOrNull;
    if (target == null) return;
    final last = s.cardsOf(target.id).lastOrNull?.position;
    final position = last == null ? kPositionGap : last + kPositionGap;
    await _optimistic(
      s.copyWith(cards: {
        ...s.cards,
        card.id: _mergeCard(card, {'listId': target.id, 'position': position}),
      }),
      () => _repo.updateCard(card.id, {'listId': target.id, 'position': position}),
    );
  }

  /// Moves a card to [listId] on [boardId], possibly a different board or
  /// project. Same-board moves just patch listId/position in place. A
  /// cross-board move drops the card (and its label/member junction rows)
  /// from this board's state optimistically — the server strips labels and
  /// non-member subscriptions on board change, and the card no longer
  /// belongs here regardless.
  Future<void> moveCardToBoard(String cardId,
      {required String boardId, required String listId, required double position}) async {
    final s = state.value;
    final card = s?.cards[cardId];
    if (s == null || card == null) return;
    if (boardId == this.boardId) {
      await _patchCard(cardId, {'listId': listId, 'position': position});
      return;
    }
    await _optimistic(
      s.copyWith(
        cards: {...s.cards}..remove(cardId),
        cardLabels: s.cardLabels.where((cl) => cl.cardId != cardId).toList(),
        cardMemberships:
            s.cardMemberships.where((m) => m.cardId != cardId).toList(),
      ),
      () => _repo.updateCard(
          cardId, {'boardId': boardId, 'listId': listId, 'position': position}),
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

  Future<void> setSubscribed(String cardId, bool isSubscribed) =>
      _patchCard(cardId, {'isSubscribed': isSubscribed});

  /// Sets or clears (null) the card's cover attachment.
  Future<void> setCover(String cardId, String? attachmentId) =>
      _patchCard(cardId, {'coverAttachmentId': attachmentId});

  /// Replaces the card's stopwatch. Running while [startedAt] is set; [total]
  /// is accumulated seconds. Pass null [stopwatch] semantics via [clearStopwatch].
  Future<void> setStopwatch(String cardId,
          {DateTime? startedAt, required int total}) =>
      _patchCard(cardId, {
        'stopwatch': {
          'startedAt': startedAt?.toUtc().toIso8601String(),
          'total': total,
        }
      });

  Future<void> clearStopwatch(String cardId) =>
      _patchCard(cardId, {'stopwatch': null});

  /// The write in flight for each (card, group, field), so the next one can be
  /// chained behind it.
  final Map<String, Future<void>> _customFieldValueWrites = {};

  /// Runs [write] once every earlier write to the same value has finished.
  /// Unlike the create paths, this key is writable over and over: raced, two
  /// edits reach the server in either order and the app folds whichever
  /// response lands last, so a slower earlier write wins and set-then-clear
  /// leaves the app holding a value the server does not have.
  Future<void> _queueCustomFieldValueWrite(String cardId, String groupId,
      String fieldId, Future<void> Function() write) {
    final key = '$cardId/$groupId/$fieldId';
    final prior = _customFieldValueWrites[key] ?? Future<void>.value();
    final next = prior.then((_) => write());
    // The queue waits on completion, not on success: a rejected write must not
    // strand the edits made after it.
    final settled = next.then((_) {}, onError: (_) {});
    _customFieldValueWrites[key] = settled;
    settled.whenComplete(() {
      if (identical(_customFieldValueWrites[key], settled)) {
        _customFieldValueWrites.remove(key);
      }
    });
    return next;
  }

  /// Sets this card's value for a (group, field) pair — the server addresses a
  /// value by that pair and has one endpoint for creating and updating it.
  /// [content] is trimmed, and blank content clears the value: the server
  /// stores no empty string, so an unset field and a cleared one are the same
  /// thing. Optimistic, so a rejected write heals back to the server's value.
  Future<void> setCustomFieldValue(String cardId,
      {required String groupId,
      required String fieldId,
      required String content}) {
    final trimmed = content.trim();
    return _queueCustomFieldValueWrite(
        cardId,
        groupId,
        fieldId,
        () => trimmed.isEmpty
            ? _clearCustomFieldValue(cardId, groupId: groupId, fieldId: fieldId)
            : _setCustomFieldValue(cardId,
                groupId: groupId, fieldId: fieldId, content: trimmed));
  }

  /// Removes the card's value for a (group, field) pair, leaving the field
  /// exactly as one that was never set.
  Future<void> clearCustomFieldValue(String cardId,
          {required String groupId, required String fieldId}) =>
      _queueCustomFieldValueWrite(
          cardId,
          groupId,
          fieldId,
          () => _clearCustomFieldValue(cardId,
              groupId: groupId, fieldId: fieldId));

  /// The write itself. Reads state at the moment it runs rather than when it
  /// was queued, so it builds on the edit before it instead of on what the
  /// field held when the user left it.
  Future<void> _setCustomFieldValue(String cardId,
      {required String groupId,
      required String fieldId,
      required String content}) async {
    final s = state.value;
    if (s == null) return;
    final existing = s.customFieldValueOf(cardId, groupId, fieldId);
    final optimistic = PlankaCustomFieldValue(
      // No id to use when the value is new; the server's row replaces this one
      // on response, matched on the (card, group, field) key.
      id: existing?.id ?? 'tmp-$cardId-$groupId-$fieldId',
      cardId: cardId,
      customFieldGroupId: groupId,
      customFieldId: fieldId,
      content: content,
    );
    await _optimistic(
      s.copyWith(
          customFieldValues:
              upsertCustomFieldValue(s.customFieldValues, optimistic)),
      () async {
        final env = await _repo.setCustomFieldValue(cardId,
            groupId: groupId, fieldId: fieldId, content: content);
        final cur = state.value;
        if (cur != null) {
          state = AsyncData(cur.copyWith(
              customFieldValues: upsertCustomFieldValue(cur.customFieldValues,
                  PlankaCustomFieldValue.fromJson(env.item))));
        }
        return env;
      },
    );
  }

  Future<void> _clearCustomFieldValue(String cardId,
      {required String groupId, required String fieldId}) async {
    final s = state.value;
    final existing = s?.customFieldValueOf(cardId, groupId, fieldId);
    // Nothing to clear: the server answers a delete of a value it does not
    // hold with a 404, which would surface to the user as a failed edit.
    if (s == null || existing == null) return;
    await _optimistic(
      s.copyWith(
          customFieldValues:
              s.customFieldValues.where((v) => v.id != existing.id).toList()),
      () => _repo.deleteCustomFieldValue(cardId,
          groupId: groupId, fieldId: fieldId),
    );
  }

  Future<void> renameBoard(String name) async {
    final s = state.value;
    if (s == null) return;
    await _optimistic(
      s.copyWith(board: PlankaBoard.fromJson({...s.board.toJson(), 'name': name})),
      () => _repo.updateBoard(boardId, {'name': name}),
    );
  }

  /// Adds a board member. The server row is folded in on response; the socket
  /// echo dedupes via _upsert. Any user rows included in the response (the new
  /// member) are merged so names/avatars resolve immediately.
  Future<void> addBoardMember(String userId, {String role = 'editor'}) async {
    final env = await _repo.addBoardMember(boardId, userId: userId, role: role);
    final cur = state.value;
    if (cur == null) return;
    var users = cur.users;
    for (final u in env.included.users) {
      users = _upsert(users, u, (x) => x.id);
    }
    state = AsyncData(cur.copyWith(
      boardMemberships: _upsert(cur.boardMemberships,
          PlankaBoardMembership.fromJson(env.item), (m) => m.id),
      users: users,
    ));
  }

  Future<void> setBoardMemberRole(String membershipId, String role) async {
    final s = state.value;
    final m =
        s?.boardMemberships.where((x) => x.id == membershipId).firstOrNull;
    if (s == null || m == null) return;
    final updated =
        PlankaBoardMembership.fromJson({...m.toJson(), 'role': role});
    await _optimistic(
      s.copyWith(
          boardMemberships: _upsert(s.boardMemberships, updated, (x) => x.id)),
      () => _repo.updateBoardMembership(membershipId, {'role': role}),
    );
  }

  Future<void> removeBoardMember(String membershipId) async {
    final s = state.value;
    if (s == null) return;
    await _optimistic(
      s.copyWith(
          boardMemberships:
              s.boardMemberships.where((m) => m.id != membershipId).toList()),
      () => _repo.removeBoardMembership(membershipId),
    );
  }

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

  Future<void> editLabel(String labelId, {String? name, String? color}) async {
    final s = state.value;
    final label = s?.labels.where((l) => l.id == labelId).firstOrNull;
    if (s == null || label == null) return;
    final patch = <String, dynamic>{
      'name': ?name,
      'color': ?color,
    };
    if (patch.isEmpty) return;
    final updated = PlankaLabel.fromJson({...label.toJson(), ...patch});
    await _optimistic(
      s.copyWith(labels: _upsert(s.labels, updated, (l) => l.id)),
      () => _repo.updateLabel(labelId, patch),
    );
  }

  Future<void> deleteLabel(String labelId) async {
    final s = state.value;
    if (s == null) return;
    await _optimistic(
      s.copyWith(
        labels: s.labels.where((l) => l.id != labelId).toList(),
        cardLabels: s.cardLabels.where((cl) => cl.labelId != labelId).toList(),
      ),
      () => _repo.deleteLabel(labelId),
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

  Future<void> renameTaskList(String id, String name) async {
    final s = state.value;
    final tl = s?.taskLists.where((t) => t.id == id).firstOrNull;
    if (s == null || tl == null) return;
    final renamed = PlankaTaskList.fromJson({...tl.toJson(), 'name': name});
    await _optimistic(
      s.copyWith(taskLists: _upsert(s.taskLists, renamed, (t) => t.id)),
      () => _repo.updateTaskList(id, {'name': name}),
    );
  }

  Future<void> deleteTaskList(String id) async {
    final s = state.value;
    if (s == null) return;
    await _optimistic(
      s.copyWith(
        taskLists: s.taskLists.where((t) => t.id != id).toList(),
        tasks: s.tasks.where((t) => t.taskListId != id).toList(),
      ),
      () => _repo.deleteTaskList(id),
    );
  }

  Future<void> renameTask(String id, String name) async {
    final s = state.value;
    final task = s?.tasks.where((t) => t.id == id).firstOrNull;
    if (s == null || task == null) return;
    final renamed = PlankaTask.fromJson({...task.toJson(), 'name': name});
    await _optimistic(
      s.copyWith(tasks: _upsert(s.tasks, renamed, (t) => t.id)),
      () => _repo.updateTask(id, {'name': name}),
    );
  }

  Future<void> deleteTask(String id) async {
    final s = state.value;
    if (s == null) return;
    await _optimistic(
      s.copyWith(tasks: s.tasks.where((t) => t.id != id).toList()),
      () => _repo.deleteTask(id),
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

  Future<void> editComment(String commentId, String text) async {
    final s = state.value;
    final comment = s?.comments.where((c) => c.id == commentId).firstOrNull;
    if (s == null || comment == null) return;
    final updated = PlankaComment.fromJson({...comment.toJson(), 'text': text});
    await _optimistic(
      s.copyWith(comments: _upsert(s.comments, updated, (c) => c.id)),
      () => _repo.updateComment(commentId, text: text),
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

  Future<void> sortList(String listId,
      {required String fieldName, String? order}) async {
    final env =
        await _repo.sortList(listId, fieldName: fieldName, order: order);
    final cur = state.value;
    if (cur == null) return;
    final sorted = env.included.cards;
    if (sorted.isEmpty) {
      await _refetch();
      return;
    }
    var cards = cur.cards;
    for (final c in sorted) {
      cards = {...cards, c.id: c};
    }
    state = AsyncData(cur.copyWith(cards: cards));
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
