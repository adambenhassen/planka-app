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
import 'user_socket.dart';

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

  /// Comment ids whose decrement has already been applied to a card's
  /// `commentsTotal` in this session (see [applyCommentDelete]). The board
  /// response carries no comment rows, so a delete arrives with the row
  /// absent whether it is the app's own echo or a remote delete of a comment
  /// the app never loaded — only this ledger tells them apart. Cleared on
  /// every load/refetch: a fresh board envelope's counts are server truth
  /// again, so no decrement may apply on top of it.
  final Set<String> deletedCommentIds;
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
    this.deletedCommentIds = const {},
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

  /// The board's members, resolved from [users]. The board response's users
  /// are a union of members and card creators, so only the boardMemberships
  /// junction marks who is actually a member — the checklist assignee picker
  /// offers exactly this list, since the server rejects a non-member.
  List<PlankaUser> get boardMembers => [
        for (final m in boardMemberships)
          ...users.where((u) => u.id == m.userId),
      ];

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

  /// Whether a checklist item renders completed. A linked item mirrors its
  /// card: completed exactly while the card is closed — the same rule the
  /// card tile uses, so a stale stored flag and the list type never disagree
  /// — regardless of the task's stored flag. An item linked to a card this
  /// state does not hold (another board's) falls back to that flag, and an
  /// unlinked one is just [PlankaTask.isCompleted].
  bool isTaskCompleted(PlankaTask task) {
    final linkedId = task.linkedCardId;
    if (linkedId == null) return task.isCompleted;
    final card = cards[linkedId];
    if (card == null) return task.isCompleted;
    final listClosed = lists.where((l) => l.id == card.listId).firstOrNull?.type ==
        PlankaListType.closed;
    return card.isClosed == true || listClosed;
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
  /// The response is authoritative for everything the templates own: fields a
  /// base group dropped while this socket was down are removed — their stored
  /// values with them, as the live delete path does — and so are the groups
  /// instantiated from a template it no longer holds, which the server
  /// cascaded away. Fields belonging to plain board or card groups, and the
  /// values under them, are untouched.
  BoardState withBaseCustomFields(Envelope projectEnv) {
    final bases = projectEnv.included.baseCustomFieldGroups;
    final baseIds = bases.map((b) => b.id).toSet();
    final orphaned = customFieldGroups
        .where((g) =>
            g.baseCustomFieldGroupId != null &&
            !baseIds.contains(g.baseCustomFieldGroupId))
        .map((g) => g.id)
        .toSet();
    final owned = projectEnv.included.customFields.map((f) => f.id).toSet();
    final droppedFields = customFields
        .where((f) => f.baseCustomFieldGroupId != null && !owned.contains(f.id))
        .map((f) => f.id)
        .toSet();
    var fields = customFields
        .where((f) => f.baseCustomFieldGroupId == null || owned.contains(f.id))
        .toList();
    for (final f in projectEnv.included.customFields) {
      fields = _upsert(fields, f, (x) => x.id);
    }
    return copyWith(
      customFieldGroups: customFieldGroups
          .where((g) => !orphaned.contains(g.id))
          .toList(),
      customFields: fields,
      customFieldValues: customFieldValues
          .where((v) =>
              !orphaned.contains(v.customFieldGroupId) &&
              !droppedFields.contains(v.customFieldId))
          .toList(),
      baseCustomFieldGroups: bases,
    );
  }

  /// Carries [old]'s base-derived data — templates and the fields they own —
  /// into this state. Used when a recovery refetch could not resolve the
  /// project fresh: the board snapshot alone renders instantiated groups as
  /// untitled empty blocks, so what was on screen before the recovery ran is
  /// kept until the next successful fetch heals it. Nothing else moves: the
  /// board envelope stays authoritative for groups, values, cards and the
  /// rest, so a server-side cascade deletion still cannot come back through
  /// here.
  BoardState withBaseDataFrom(BoardState old) {
    final fieldIds = customFields.map((f) => f.id).toSet();
    return copyWith(
      baseCustomFieldGroups: [
        ...baseCustomFieldGroups,
        ...old.baseCustomFieldGroups.where((b) =>
            !baseCustomFieldGroups.any((x) => x.id == b.id)),
      ],
      customFields: [
        ...customFields,
        ...old.customFields.where((f) =>
            f.baseCustomFieldGroupId != null && !fieldIds.contains(f.id)),
      ],
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
    Set<String>? deletedCommentIds,
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
        deletedCommentIds: deletedCommentIds ?? this.deletedCommentIds,
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

/// The card tile's comment count, kept live by the comment transitions below:
/// Planka broadcasts `commentCreate`/`commentDelete` without touching the card
/// row, so the server-stored count moves only there. The count is a delta over
/// the server-seeded `commentsTotal`, never derived from [BoardState.comments]
/// (the app holds rows only for cards it opened), and the floor is zero.
Map<String, PlankaCard> _bumpCommentCounts(
    BoardState s, String? cardId, int delta) {
  final card = cardId == null ? null : s.cards[cardId];
  if (card == null) return s.cards;
  final next = (card.commentsTotal ?? 0) + delta;
  final updated = PlankaCard.fromJson(
      {...card.toJson(), 'commentsTotal': next < 0 ? 0 : next});
  return {...s.cards, card.id: updated};
}

/// The commentCreate transition, shared by the socket event and the app's own
/// create-response fold. The row is upserted, and the count moves only when
/// the transition actually adds a row that was not there: the optimistic fold
/// counts, and its echo — or any replay of the same create — is a no-op on the
/// count. `commentUpdate` needs no count move at all.
BoardState applyCommentCreate(BoardState s, PlankaComment comment) {
  final rowKnown = s.comments.any((c) => c.id == comment.id);
  return s.copyWith(
    comments: _upsert(s.comments, comment, (c) => c.id),
    cards: rowKnown ? s.cards : _bumpCommentCounts(s, comment.cardId, 1),
  );
}

/// The commentDelete transition, shared by the socket event and the app's own
/// optimistic delete. The row is removed, and the count decrements unless the
/// ledger already holds [commentId] — the app's own delete echo and a replayed
/// remote delete both arrive with the row already gone, and only the ledger
/// tells them apart from a genuine delete of a comment the app never loaded,
/// which still decrements. Bounded by the deletes seen in one session: it is
/// never persisted and dies with the state on load/refetch.
BoardState applyCommentDelete(BoardState s, String commentId, String? cardId) {
  final already = s.deletedCommentIds.contains(commentId);
  return s.copyWith(
    comments: s.comments.where((c) => c.id != commentId).toList(),
    cards: already ? s.cards : _bumpCommentCounts(s, cardId, -1),
    deletedCommentIds:
        already ? s.deletedCommentIds : {...s.deletedCommentIds, commentId},
  );
}

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

/// The events a board takes off the user's own room. Planka broadcasts changes
/// to a project's base custom field groups — and to the fields on them — there
/// rather than to the board room, so a board whose groups are instantiated from
/// a template learns about them nowhere else. Everything else that room carries
/// (notifications, the user list) belongs to whoever else listens to it.
const kBoardUserRoomEvents = {
  'baseCustomFieldGroupCreate',
  'baseCustomFieldGroupUpdate',
  'baseCustomFieldGroupDelete',
  'customFieldCreate',
  'customFieldUpdate',
  'customFieldDelete',
};

/// Whether a base custom field group event names the project this board is in.
/// The user room carries every project the account can see, so an event for
/// another one must leave this board's state exactly as it was.
bool _isThisProject(BoardState s, Map<String, dynamic> item) =>
    item['projectId'] == null
        ? s.baseCustomFieldGroups.any((b) => b.id == item['id'])
        : item['projectId'] == s.board.projectId;

/// Whether a custom field event is this board's. A field keyed to a board or
/// card group came from the board room and always is; one keyed to a base group
/// only if that template belongs to this project. A reposition carries neither
/// key — just `{id, position}` — so there it comes down to already holding the
/// field.
bool _isThisBoardsField(BoardState s, Map<String, dynamic> item) {
  final baseId = item['baseCustomFieldGroupId'] as String?;
  if (baseId != null) return s.baseCustomFieldGroups.any((b) => b.id == baseId);
  if (item['customFieldGroupId'] != null) return true;
  return s.customFields.any((f) => f.id == item['id']);
}

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
      // Merged like every other upserted row: a reposition can broadcast a
      // partial payload, which must not blank the assignee or linked card.
      return s.copyWith(
          tasks: _upsert(
              s.tasks,
              _mergeById(s.tasks.where((t) => t.id == id).firstOrNull, item,
                  (PlankaTask t) => t.toJson(), PlankaTask.fromJson),
              (t) => t.id));
    case 'taskDelete':
      return s.copyWith(tasks: s.tasks.where((t) => t.id != id).toList());
    case 'attachmentCreate' || 'attachmentUpdate':
      return s.copyWith(
          attachments: _upsert(
              s.attachments, PlankaAttachment.fromJson(item), (a) => a.id));
    case 'attachmentDelete':
      return s.copyWith(
          attachments: s.attachments.where((a) => a.id != id).toList());
    case 'commentCreate':
      return applyCommentCreate(s, PlankaComment.fromJson(item));
    case 'commentUpdate':
      // Text changes; the count stays.
      return s.copyWith(
          comments:
              _upsert(s.comments, PlankaComment.fromJson(item), (c) => c.id));
    case 'commentDelete':
      if (id == null) return s;
      return applyCommentDelete(s, id, item['cardId'] as String?);
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
      if (id == null || !_isThisBoardsField(s, item)) return s;
      final field = _mergeById(
          s.customFields.where((f) => f.id == id).firstOrNull,
          item,
          (PlankaCustomField f) => f.toJson(),
          PlankaCustomField.fromJson);
      return s.copyWith(
          customFields: _upsert(s.customFields, field, (f) => f.id));
    case 'customFieldDelete':
      if (!_isThisBoardsField(s, item)) return s;
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
    case 'baseCustomFieldGroupCreate' || 'baseCustomFieldGroupUpdate':
      if (id == null || !_isThisProject(s, item)) return s;
      final base = _mergeById(
          s.baseCustomFieldGroups.where((b) => b.id == id).firstOrNull,
          item,
          (PlankaBaseCustomFieldGroup b) => b.toJson(),
          PlankaBaseCustomFieldGroup.fromJson);
      return s.copyWith(
          baseCustomFieldGroups:
              _upsert(s.baseCustomFieldGroups, base, (b) => b.id));
    case 'baseCustomFieldGroupDelete':
      if (id == null || !_isThisProject(s, item)) return s;
      // The server deletes the groups instantiated from the template itself and
      // broadcasts nothing for them on the board room, so the whole cascade
      // happens here or they stay on screen pointing at a template that's gone.
      final orphaned = s.customFieldGroups
          .where((g) => g.baseCustomFieldGroupId == id)
          .map((g) => g.id)
          .toSet();
      return s.copyWith(
        baseCustomFieldGroups:
            s.baseCustomFieldGroups.where((b) => b.id != id).toList(),
        customFieldGroups: s.customFieldGroups
            .where((g) => g.baseCustomFieldGroupId != id)
            .toList(),
        customFields:
            s.customFields.where((f) => f.baseCustomFieldGroupId != id).toList(),
        customFieldValues: s.customFieldValues
            .where((v) => !orphaned.contains(v.customFieldGroupId))
            .toList(),
      );
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

/// Comments are not part of the board response, so load them when a card
/// detail sheet opens. The notifier folds the result into the board state so
/// socket events and comment mutations continue to share one collection.
final cardCommentsProvider = FutureProvider.autoDispose
    .family<List<PlankaComment>, (String, String)>((ref, args) async {
  final notifier = ref.read(boardProvider(args.$1).notifier);
  return notifier.fetchComments(args.$2);
});

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

  /// A custom field group instantiated from a project base group takes its
  /// name and fields from that template, which the board response omits — so
  /// fetch the project, but only for a board that actually has such a group.
  /// With [fresh] the fold never answers from the offline cache: it is used by
  /// recovery and reconnect refetches, which act as authoritative
  /// reconciliation sources a stale cache must not feed (see
  /// [_freshProjectEnvelope]). Initial load keeps the fallback — offline,
  /// a cached name beats none.
  Future<BoardState> _withBaseCustomFields(BoardState s,
      {bool fresh = false}) async {
    if (!s.needsBaseCustomFields) return s;
    final env = fresh
        ? await _freshProjectEnvelope(s.board.projectId)
        : await _projectEnvelope(s.board.projectId);
    return env == null ? s : s.withBaseCustomFields(env);
  }

  /// The project response, or null when it cannot be read.
  Future<Envelope?> _projectEnvelope(String projectId) async {
    final account = ref.read(currentAccountProvider);
    if (account == null) return null;
    try {
      final env = await ref.read(envelopeCacheProvider).fetchOrCached(
          '${account.id}-project-$projectId', () => _repo.project(projectId));
      return env;
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

  /// Same fetch, but never answered from the offline cache. This is the
  /// reconciliation path: the cache can predate a deletion made while our
  /// socket was down, and treating it as authoritative would resurrect what
  /// was deleted. A failure here leaves state as it stands — the next
  /// reconnect edge or event retries.
  Future<Envelope?> _freshProjectEnvelope(String projectId) async {
    final account = ref.read(currentAccountProvider);
    if (account == null) return null;
    try {
      final env = await _repo.project(projectId);
      unawaited(
          ref.read(envelopeCacheProvider).put('${account.id}-project-$projectId', env));
      return env;
    } on ApiException catch (e) {
      debugPrint('board $boardId: base custom fields resync failed: $e');
      return null;
    }
  }

  /// Holds the fetch below to one at a time, however many events arrive while
  /// it is in flight — a group create is usually followed by its fields.
  bool _fillingBaseCustomFields = false;

  /// Bumped for every event off the user room that actually changed this
  /// board's state — cross-project events pass through untouched and must not
  /// count. The reconciliation fetch below compares counts across its await:
  /// a state-changing event landing mid-fetch is newer than the response that
  /// just answered, and installing that response would clobber or resurrect
  /// what the event changed — so it is discarded and fetched again instead.
  int _userRoomEventsSeen = 0;

  /// Same fetch as [_withBaseCustomFields], for a group instantiated while the
  /// board is open — it arrives over the socket with neither its name nor its
  /// fields — and for reconnect resyncs. Folded into whatever state is current
  /// when the project answers; serialized behind any room events that land
  /// while the fetch is in flight.
  Future<void> _fillBaseCustomFields() async {
    if (_fillingBaseCustomFields) return;
    _fillingBaseCustomFields = true;
    try {
      while (true) {
        final projectId = state.value?.board.projectId;
        if (projectId == null) return;
        final seenBeforeFetch = _userRoomEventsSeen;
        final env = await _freshProjectEnvelope(projectId);
        final cur = state.value;
        if (env == null || cur == null) return;
        if (_userRoomEventsSeen != seenBeforeFetch) continue;
        state = AsyncData(cur.withBaseCustomFields(env));
        return;
      }
    } finally {
      _fillingBaseCustomFields = false;
    }
  }

  /// Folds the project-level custom field events off the shared user room into
  /// this board, ignoring the rest of what that room carries. The room's socket
  /// is already connected while the board builds, so changes landing during
  /// [load] are buffered and folded into the snapshot by calling the returned
  /// function with it; from then on events apply as they arrive. Folding into
  /// the snapshot rather than replaying after it keeps an event that preceded
  /// the fetch from resurrecting data the fetch saw past. Takes the stream as
  /// an argument so a test can drive it without a live socket.
  BoardState Function(BoardState snapshot) listenToUserRoom(
      Stream<SocketEvent> events) {
    final pending = <SocketEvent>[];
    var live = false;
    void apply(SocketEvent e) {
      final before = state.value;
      applySocketEvent(e);
      // Only an event that actually changed this board invalidates an
      // in-flight reconciliation — the room carries every project the account
      // can see, and a busy one must not starve this board's resync by
      // discarding valid responses it had nothing to do with.
      if (!identical(state.value, before)) _userRoomEventsSeen++;
    }

    late final StreamSubscription<SocketEvent> sub;
    sub = events
        .where((e) => kBoardUserRoomEvents.contains(e.name))
        .listen((e) => live ? apply(e) : pending.add(e), onError: (Object e) {
      debugPrint('user room socket error: $e');
      recoverRealtime(userRoom: true);
    });
    // The room outlives this board when another screen is watching it, so hand
    // the subscription back rather than relying on the socket being disposed.
    ref.onDispose(sub.cancel);
    return (BoardState snapshot) {
      live = true;
      var s = snapshot;
      for (final e in pending) {
        final before = s;
        s = applyEvent(s, e);
        if (!identical(s, before)) _userRoomEventsSeen++;
      }
      pending.clear();
      // A template instantiated during the buffer needs the project fetch that
      // [applySocketEvent] would have triggered — but state is not installed
      // yet, so latch it for [listenSelf] to fire once it is.
      if (s.needsBaseCustomFields) _baseResyncPending = true;
      return s;
    };
  }

  /// Watches the shared user room and returns the fold that turns the REST
  /// snapshot into current state (see [listenToUserRoom]), plus a resync of
  /// everything this board takes off that room whenever the room reconnects —
  /// each event is sent once, to whoever is joined at that moment, so changes
  /// emitted while the socket was down never arrive and only a refetch heals
  /// them. An edge landing before the state exists (the initial build racing
  /// the room's socket) is latched and resynced right after build installs it.
  /// Protected so a test subclass can run the exact production wiring without
  /// the board socket.
  @protected
  BoardState Function(BoardState snapshot) wireUserRoom() {
    final userEvents = ref.watch(userEventsProvider);
    final userConnected = ref.watch(userConnectedProvider);
    final fold = listenToUserRoom(userEvents);
    final selfSub = listenSelf((previous, next) {
      if (_baseResyncPending && next.hasValue) {
        _baseResyncPending = false;
        unawaited(_fillBaseCustomFields());
      }
    });
    ref.onDispose(selfSub);
    final connSub = userConnected.listen((c) {
      if (!c) return;
      if (state.value != null) {
        unawaited(_fillBaseCustomFields());
      } else {
        _baseResyncPending = true;
      }
    });
    ref.onDispose(connSub.cancel);
    return fold;
  }

  /// Set when a base-data resync is owed but cannot run yet because the board
  /// is still building; consumed by the [ref.listenSelf] hook in
  /// [wireUserRoom] the moment real state exists.
  bool _baseResyncPending = false;

  DateTime? _lastRealtimeRecovery;
  DateTime? _lastUserJoinRetry;
  DateTime? _lastBoardJoinRetry;

  /// Realtime errors mean events are being missed while the transport may look
  /// healthy — a permanently refused subscribe leaves no disconnect to react
  /// to. Heal with a full refetch instead of trusting the log line alone,
  /// coalesced across both sockets so an error storm costs one reload — and
  /// re-issue the failed room's join in the same stroke: data alone doesn't
  /// restore membership, and a socket that stays unjoined keeps losing every
  /// later event. Join retries are bounded per room, so one socket's failure
  /// never suppresses the other's.
  @protected
  void recoverRealtime({bool userRoom = false}) {
    final now = DateTime.now();
    final lastRefetch = _lastRealtimeRecovery;
    if (lastRefetch == null ||
        now.difference(lastRefetch) >= const Duration(seconds: 30)) {
      _lastRealtimeRecovery = now;
      unawaited(_refetch());
    }
    final lastJoin = userRoom ? _lastUserJoinRetry : _lastBoardJoinRetry;
    if (lastJoin != null &&
        now.difference(lastJoin) < const Duration(seconds: 30)) {
      return;
    }
    if (userRoom) {
      _lastUserJoinRetry = now;
      rejoinUserRoom();
    } else {
      _lastBoardJoinRetry = now;
      rejoinBoardRoom();
    }
  }

  /// The user room's join, retried by recovery. Protected so tests can count
  /// retries without a live socket.
  @protected
  void rejoinUserRoom() =>
      unawaited(ref.read(userSocketProvider)?.subscribeUser());

  /// Same for the board room.
  @protected
  void rejoinBoardRoom() => unawaited(_socket?.subscribeBoard(boardId));

  @override
  Future<BoardState> build() async {
    final account = ref.read(currentAccountProvider)!;
    // From here the room may deliver at any moment; buffer until the snapshot
    // is folded (see [listenToUserRoom]).
    final foldUserRoom = wireUserRoom();
    final loaded = await load();
    final socket = PlankaSocket(account.serverUrl, account.token);
    _socket = socket;
    ref.onDispose(socket.dispose);
    // A stream/subscribe error only degrades realtime — the REST-loaded board
    // is still valid, hard disconnects surface via _ConnectionBanner, and a
    // reconnect re-subscribes (onConnect) then refetches. So we log rather
    // than alarm the user — but since an error also means missed events on a
    // possibly healthy transport, recover with a coalesced refetch.
    socket.events.listen(applySocketEvent, onError: (Object e) {
      debugPrint('board socket error: $e');
      recoverRealtime();
    });
    socket.connected.listen((c) {
      // On reconnect the socket re-subscribes itself; refetch to fill the gap.
      if (c) _refetch();
    });
    await socket.connect();
    await socket.subscribeBoard(boardId);
    return foldUserRoom(loaded);
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
      final prev = state.value;
      var next = BoardState.fromEnvelope(env);
      next = await _withBaseCustomFields(next, fresh: true);
      // When the fresh project fetch fails, the fold above returns the raw
      // board snapshot — which carries no base data at all. Installing that
      // would drop every instantiated group's name and fields off the open
      // board: the round-4 resurrection vector arriving through the board
      // response instead of the cached project one. Carry what we were
      // already rendering forward instead — no worse than before recovery —
      // and let the next edge, event or join retry heal.
      if (prev != null && next.needsBaseCustomFields) {
        next = next.withBaseDataFrom(prev);
      }
      state = AsyncData(next);
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
    // The board's defaultCardType decides what a new card is; when
    // limitCardTypesToDefaultOne is set the server rejects any other type, and
    // the app offers no type picker anyway.
    await _createInto(
      _repo.createCard(listId,
          type: s.board.defaultCardType ?? 'project',
          name: name,
          position:
              last == null ? kPositionGap : last + kPositionGap),
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

  // --------------- Custom field group mutations ---------------

  List<PlankaCustomFieldGroup> _boardGroups(BoardState s) =>
      s.customFieldGroups.where((g) => g.boardId == s.board.id).toList()
        ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

  List<PlankaCustomFieldGroup> _cardGroups(BoardState s, String cardId) =>
      s.customFieldGroups.where((g) => g.cardId == cardId).toList()
        ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

  Future<void> createBoardCustomFieldGroup(String name) async {
    final s = state.value;
    if (s == null) return;
    final groups = _boardGroups(s);
    final position = positionBetween(groups.lastOrNull?.position, null);
    await _createInto(
      _repo.createBoardCustomFieldGroup(boardId,
          name: name, position: position),
      PlankaCustomFieldGroup.fromJson,
      (b, g) => b.copyWith(
          customFieldGroups: _upsert(b.customFieldGroups, g, (x) => x.id)),
    );
  }

  Future<void> createCardCustomFieldGroup(String cardId, String name) async {
    final s = state.value;
    if (s == null) return;
    final groups = _cardGroups(s, cardId);
    final position = positionBetween(groups.lastOrNull?.position, null);
    await _createInto(
      _repo.createCardCustomFieldGroup(cardId,
          name: name, position: position),
      PlankaCustomFieldGroup.fromJson,
      (b, g) => b.copyWith(
          customFieldGroups: _upsert(b.customFieldGroups, g, (x) => x.id)),
    );
  }

  Future<void> renameCustomFieldGroup(String id, String name) async {
    final s = state.value;
    final group = s?.customFieldGroups.where((g) => g.id == id).firstOrNull;
    if (s == null || group == null) return;
    final updated = PlankaCustomFieldGroup.fromJson(
        {...group.toJson(), 'name': name});
    await _optimistic(
      s.copyWith(
          customFieldGroups: _upsert(s.customFieldGroups, updated, (g) => g.id)),
      () => _repo.updateCustomFieldGroup(id, {'name': name}),
    );
  }

  Future<void> moveCustomFieldGroupUp(String id) =>
      _moveCustomFieldGroup(id, up: true);

  Future<void> moveCustomFieldGroupDown(String id) =>
      _moveCustomFieldGroup(id, up: false);

  Future<void> _moveCustomFieldGroup(String id, {required bool up}) async {
    final s = state.value;
    final group = s?.customFieldGroups.where((g) => g.id == id).firstOrNull;
    if (s == null || group == null) return;
    final peers = group.boardId != null
        ? _boardGroups(s)
        : group.cardId != null
            ? _cardGroups(s, group.cardId!)
            : <PlankaCustomFieldGroup>[];
    final idx = peers.indexWhere((g) => g.id == id);
    if (idx < 0) return;
    final double position;
    if (up) {
      if (idx == 0) return;
      final before = idx > 1 ? peers[idx - 2].position : null;
      final after = peers[idx - 1].position;
      position = positionBetween(before, after);
    } else {
      if (idx >= peers.length - 1) return;
      final before = peers[idx + 1].position;
      final after = idx + 2 < peers.length ? peers[idx + 2].position : null;
      position = positionBetween(before, after);
    }
    final updated = PlankaCustomFieldGroup.fromJson(
        {...group.toJson(), 'position': position});
    await _optimistic(
      s.copyWith(
          customFieldGroups: _upsert(s.customFieldGroups, updated, (g) => g.id)),
      () => _repo.updateCustomFieldGroup(id, {'position': position}),
    );
  }

  Future<void> deleteCustomFieldGroup(String id) async {
    final s = state.value;
    if (s == null) return;
    await _optimistic(
      s.copyWith(
        customFieldGroups:
            s.customFieldGroups.where((g) => g.id != id).toList(),
        customFields:
            s.customFields.where((f) => f.customFieldGroupId != id).toList(),
        customFieldValues:
            s.customFieldValues.where((v) => v.customFieldGroupId != id).toList(),
      ),
      () => _repo.deleteCustomFieldGroup(id),
    );
  }

  /// Instantiates a project template onto this board. The server row is
  /// folded in on response (the socket echo dedupes via upsert); the group
  /// borrows its name and fields from the template, so the project fetch that
  /// supplies those is run right away instead of waiting for the socket edge.
  Future<void> instantiateTemplateOnBoard(String baseCustomFieldGroupId) async {
    final s = state.value;
    if (s == null) return;
    final position = positionBetween(_boardGroups(s).lastOrNull?.position, null);
    await _createInto(
      _repo.createBoardCustomFieldGroupFromTemplate(boardId,
          baseCustomFieldGroupId: baseCustomFieldGroupId, position: position),
      PlankaCustomFieldGroup.fromJson,
      (b, g) => b.copyWith(
          customFieldGroups: _upsert(b.customFieldGroups, g, (x) => x.id)),
    );
    await _fillBaseCustomFields();
  }

  // --------------- Custom field mutations ---------------

  List<PlankaCustomField> _groupFields(BoardState s, String groupId) =>
      s.customFields.where((f) => f.customFieldGroupId == groupId).toList()
        ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

  Future<void> createCustomField(String groupId, String name) async {
    final s = state.value;
    if (s == null) return;
    final fields = _groupFields(s, groupId);
    final position = positionBetween(fields.lastOrNull?.position, null);
    await _createInto(
      _repo.createCustomField(groupId, name: name, position: position),
      PlankaCustomField.fromJson,
      (b, f) => b.copyWith(
          customFields: _upsert(b.customFields, f, (x) => x.id)),
    );
  }

  Future<void> renameCustomField(String id, String name) async {
    final s = state.value;
    final field = s?.customFields.where((f) => f.id == id).firstOrNull;
    if (s == null || field == null) return;
    final updated =
        PlankaCustomField.fromJson({...field.toJson(), 'name': name});
    await _optimistic(
      s.copyWith(customFields: _upsert(s.customFields, updated, (f) => f.id)),
      () => _repo.updateCustomField(id, {'name': name}),
    );
  }

  Future<void> toggleCustomFieldFrontOfCard(String id, bool show) async {
    final s = state.value;
    final field = s?.customFields.where((f) => f.id == id).firstOrNull;
    if (s == null || field == null) return;
    final updated = PlankaCustomField.fromJson(
        {...field.toJson(), 'showOnFrontOfCard': show});
    await _optimistic(
      s.copyWith(customFields: _upsert(s.customFields, updated, (f) => f.id)),
      () => _repo.updateCustomField(id, {'showOnFrontOfCard': show}),
    );
  }

  Future<void> moveCustomFieldUp(String id) => _moveCustomField(id, up: true);

  Future<void> moveCustomFieldDown(String id) =>
      _moveCustomField(id, up: false);

  Future<void> _moveCustomField(String id, {required bool up}) async {
    final s = state.value;
    final field = s?.customFields.where((f) => f.id == id).firstOrNull;
    if (s == null || field == null) return;
    final groupId = field.customFieldGroupId;
    if (groupId == null) return;
    final peers = _groupFields(s, groupId);
    final idx = peers.indexWhere((f) => f.id == id);
    if (idx < 0) return;
    final double position;
    if (up) {
      if (idx == 0) return;
      final before = idx > 1 ? peers[idx - 2].position : null;
      final after = peers[idx - 1].position;
      position = positionBetween(before, after);
    } else {
      if (idx >= peers.length - 1) return;
      final before = peers[idx + 1].position;
      final after = idx + 2 < peers.length ? peers[idx + 2].position : null;
      position = positionBetween(before, after);
    }
    final updated =
        PlankaCustomField.fromJson({...field.toJson(), 'position': position});
    await _optimistic(
      s.copyWith(customFields: _upsert(s.customFields, updated, (f) => f.id)),
      () => _repo.updateCustomField(id, {'position': position}),
    );
  }

  Future<void> deleteCustomField(String id) async {
    final s = state.value;
    if (s == null) return;
    await _optimistic(
      s.copyWith(
        customFields: s.customFields.where((f) => f.id != id).toList(),
        customFieldValues:
            s.customFieldValues.where((v) => v.customFieldId != id).toList(),
      ),
      () => _repo.deleteCustomField(id),
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

  Future<void> setTaskAssignee(String taskId, String? userId) async {
    final s = state.value;
    final task = s?.tasks.where((t) => t.id == taskId).firstOrNull;
    if (s == null || task == null) return;
    final updated =
        PlankaTask.fromJson({...task.toJson(), 'assigneeUserId': userId});
    await _optimistic(
      s.copyWith(tasks: _upsert(s.tasks, updated, (t) => t.id)),
      () => _repo.updateTask(taskId, {'assigneeUserId': userId}),
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
      // The same transition the socket event folds: the count moves only when
      // the row is new, so the response fold and its echo — in either order —
      // move it exactly once.
      applyCommentCreate,
    );
  }

  /// Loads a card's comments and merges them into the current board snapshot.
  /// The merge is against the state that exists when the request answers, so a
  /// socket comment arriving while the request is in flight is preserved. The
  /// id-based upsert also folds the REST row and a socket row into one item.
  Future<List<PlankaComment>> fetchComments(String cardId) async {
    final env = await _repo.comments(cardId);
    final fetched = <PlankaComment>[];
    final rows = env.items.isNotEmpty
        ? env.items
        : env.included.comments.map((comment) => comment.toJson()).toList();
    for (final row in rows) {
      final comment = PlankaComment.fromJson(row);
      if (comment.cardId != cardId) continue;
      if (!fetched.any((existing) => existing.id == comment.id)) {
        fetched.add(comment);
      }
    }

    final current = state.value;
    if (current == null) return fetched;
    var comments = current.comments;
    for (final comment in fetched) {
      if (current.deletedCommentIds.contains(comment.id)) continue;
      comments = _upsert(comments, comment, (c) => c.id);
    }
    state = AsyncData(current.copyWith(comments: comments));
    return fetched;
  }

  Future<void> deleteComment(String commentId) async {
    final s = state.value;
    if (s == null) return;
    final cardId = s.comments
        .where((c) => c.id == commentId)
        .firstOrNull
        ?.cardId;
    // The same transition the socket event folds: the decrement is recorded in
    // the ledger, so the echo of this write no-ops on the count, and the row's
    // removal is what a genuine remote delete of a never-loaded comment still
    // decrements on.
    await _optimistic(
      applyCommentDelete(s, commentId, cardId),
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
