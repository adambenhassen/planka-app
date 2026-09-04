import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/api/planka_socket.dart';
import 'package:planka_app/state/board_state.dart';

BoardState seed() => BoardState.fromEnvelope(Envelope.parse(
    jsonDecode(File('test/fixtures/board_show.json').readAsStringSync())
        as Map<String, dynamic>));

SocketEvent ev(String name, Map<String, dynamic> payload) =>
    SocketEvent.parse(name, payload);

void main() {
  test('seeds from board_show fixture', () {
    final s = seed();
    expect(s.columns, isNotEmpty);
    expect(s.cards, isNotEmpty);
    expect(s.cardsOf(s.columns.first.id), isNotEmpty);
  });

  test('cardCreate adds', () {
    final s = seed();
    final listId = s.columns.first.id;
    final next = applyEvent(
        s,
        ev('cardCreate', {
          'item': {
            'id': 'new1',
            'boardId': s.board.id,
            'listId': listId,
            'type': 'project',
            'name': 'New card',
            'position': 99999,
          }
        }));
    expect(next.cards['new1']!.name, 'New card');
    expect(next.cardsOf(listId).last.id, 'new1');
  });

  test('cardUpdate with partial payload merges and resorts', () {
    final s = seed();
    final card = s.cards.values.first;
    final next = applyEvent(
        s, ev('cardUpdate', {'item': {'id': card.id, 'position': 1.0}}));
    final updated = next.cards[card.id]!;
    expect(updated.position, 1.0);
    expect(updated.name, card.name, reason: 'merge keeps unrelated fields');
    expect(next.cardsOf(card.listId).first.id, card.id);
  });

  test('labelUpdate with partial payload keeps name and color', () {
    final s = seed();
    final label = s.labels.first;
    final next = applyEvent(
        s, ev('labelUpdate', {'item': {'id': label.id, 'position': 1.0}}));
    final updated = next.labels.firstWhere((l) => l.id == label.id);
    expect(updated.position, 1.0);
    expect(updated.name, label.name);
    expect(updated.color, label.color);
  });

  test('listUpdate with partial payload keeps name and boardId', () {
    final s = seed();
    final list = s.columns.first;
    final next = applyEvent(
        s, ev('listUpdate', {'item': {'id': list.id, 'position': 1.0}}));
    final updated = next.lists.firstWhere((l) => l.id == list.id);
    expect(updated.position, 1.0);
    expect(updated.name, list.name);
    expect(updated.boardId, list.boardId);
    expect(next.columns.first.id, list.id,
        reason: 'ordering follows the new position');
  });

  test('taskListUpdate with partial payload keeps name and cardId', () {
    final s = seed();
    final taskList = s.taskLists.first;
    final next = applyEvent(
        s,
        ev('taskListUpdate', {
          'item': {'id': taskList.id, 'position': 1.0}
        }));
    final updated = next.taskLists.firstWhere((t) => t.id == taskList.id);
    expect(updated.position, 1.0);
    expect(updated.name, taskList.name);
    expect(updated.cardId, taskList.cardId);
    expect(next.taskListsOf(taskList.cardId).first.id, taskList.id,
        reason: 'ordering follows the new position');
  });

  test('a partial update on an unknown row is a no-op', () {
    final s = seed();
    const unknownId = 'row-new';
    const partial = {'id': unknownId, 'position': 2.0};

    expect(
        () => applyEvent(s, ev('labelUpdate', {'item': partial})),
        returnsNormally);
    expect(
        applyEvent(s, ev('labelUpdate', {'item': partial})).labels, s.labels);

    expect(
        () => applyEvent(s, ev('listUpdate', {'item': partial})),
        returnsNormally);
    expect(applyEvent(s, ev('listUpdate', {'item': partial})).lists, s.lists);

    expect(
        () => applyEvent(s, ev('taskListUpdate', {'item': partial})),
        returnsNormally);
    expect(
        applyEvent(s, ev('taskListUpdate', {'item': partial})).taskLists,
        s.taskLists);

    expect(
        () => applyEvent(s, ev('taskUpdate', {'item': partial})),
        returnsNormally);
    expect(applyEvent(s, ev('taskUpdate', {'item': partial})).tasks, s.tasks);
  });

  test('listUpdate with a full payload upserts an unknown row', () {
    final s = seed();
    const unknownId = 'list-new';
    final next = applyEvent(
        s,
        ev('listUpdate', {
          'item': {
            'id': unknownId,
            'boardId': s.board.id,
            'type': 'active',
            'name': 'Inbox',
            'position': 2.0,
          }
        }));
    expect(next.lists.map((l) => l.id), contains(unknownId));
    expect(next.lists.firstWhere((l) => l.id == unknownId).name, 'Inbox');
  });

  test('labelUpdate with a full payload upserts an unknown row', () {
    final s = seed();
    const unknownId = 'label-new';
    final next = applyEvent(
        s,
        ev('labelUpdate', {
          'item': {
            'id': unknownId,
            'boardId': s.board.id,
            'name': 'new',
            'color': 'lagoon-blue',
            'position': 2.0,
          }
        }));
    expect(next.labels.map((l) => l.id), contains(unknownId));
    expect(next.labels.firstWhere((l) => l.id == unknownId).color, 'lagoon-blue');
  });

  test('taskListUpdate with a full payload upserts an unknown row', () {
    final s = seed();
    const unknownId = 'tl-new';
    final cardId = s.cards.keys.first;
    final next = applyEvent(
        s,
        ev('taskListUpdate', {
          'item': {
            'id': unknownId,
            'cardId': cardId,
            'name': 'Checklist',
            'position': 2.0,
          }
        }));
    expect(next.taskLists.map((t) => t.id), contains(unknownId));
    expect(next.taskLists.firstWhere((t) => t.id == unknownId).cardId, cardId);
  });

  test('taskUpdate with a full payload upserts an unknown row', () {
    final s = seed();
    const unknownId = 'task-new';
    final taskListId = s.taskLists.first.id;
    final next = applyEvent(
        s,
        ev('taskUpdate', {
          'item': {
            'id': unknownId,
            'taskListId': taskListId,
            'name': 'Do it',
            'isCompleted': false,
            'position': 2.0,
          }
        }));
    expect(next.tasks.map((t) => t.id), contains(unknownId));
    expect(next.tasks.firstWhere((t) => t.id == unknownId).name, 'Do it');
  });

  test('cardDelete removes', () {
    final s = seed();
    final id = s.cards.keys.first;
    expect(applyEvent(s, ev('cardDelete', {'item': {'id': id}})).cards,
        isNot(contains(id)));
  });

  test('commentCreate adds', () {
    final s = seed();
    final next = applyEvent(
        s,
        ev('commentCreate', {
          'item': {
            'id': 'cm1',
            'cardId': s.cards.keys.first,
            'userId': 'u1',
            'text': 'hi',
          }
        }));
    expect(next.comments.map((c) => c.id), contains('cm1'));
  });

  test('commentCreate moves only its own card tile comment count', () {
    final s = seed();
    final firstCardId = s.cards.values.first.id;
    final secondCard = PlankaCard.fromJson({
      'id': 'c2',
      'boardId': s.board.id,
      'listId': s.columns.first.id,
      'type': 'project',
      'name': 'Other card',
      'position': 32768,
      'commentsTotal': 4,
    });
    final withTwo = s.copyWith(cards: {...s.cards, secondCard.id: secondCard});

    final next = applyEvent(
        withTwo,
        ev('commentCreate', {
          'item': {
            'id': 'cm1',
            'cardId': firstCardId,
            'userId': 'u1',
            'text': 'hi',
          }
        }));

    expect(next.cards[firstCardId]!.commentsTotal, 2);
    expect(next.cards['c2']!.commentsTotal, 4,
        reason: 'no other card\'s count changes');
  });

  test('commentCreate for an unknown card leaves the board untouched', () {
    final s = seed();
    final next = applyEvent(
        s,
        ev('commentCreate', {
          'item': {
            'id': 'cm1',
            'cardId': 'no-such-card',
            'userId': 'u1',
            'text': 'hi',
          }
        }));
    expect(next.cards, s.cards);
  });

  test('commentDelete decrements and never goes below zero', () {
    final s = seed();
    final cardId = s.cards.values.first.id;
    // The fixture card reports one comment but the board response carries no
    // comment rows, so state never knew one was created: its own count moves.
    expect(applyEvent(
        s,
        ev('commentDelete', {'item': {'id': 'cm9', 'cardId': cardId}}))
        .cards[cardId]!
        .commentsTotal,
        0);
    expect(applyEvent(
        s,
        ev('commentDelete', {'item': {'id': 'cm9', 'cardId': cardId}}))
        .cards[cardId]!
        .commentsTotal,
        0, reason: 'stays at zero, never negative');

    // A comment the state already holds: this delete decrements, and the
    // replayed delete of the now-absent row is a no-op — the ledger, not row
    // presence, decides it.
    final withComment = s.copyWith(comments: [
      PlankaComment.fromJson({
        'id': 'cm1',
        'cardId': cardId,
        'userId': 'u1',
        'text': 'hi',
      })
    ]);
    final afterDelete = applyEvent(
        withComment,
        ev('commentDelete', {'item': {'id': 'cm1', 'cardId': cardId}}));
    expect(afterDelete.cards[cardId]!.commentsTotal, 0);
    expect(applyEvent(
        afterDelete,
        ev('commentDelete', {'item': {'id': 'cm1', 'cardId': cardId}}))
        .cards[cardId]!
        .commentsTotal,
        0, reason: 'the replayed delete moves the count exactly once');
  });

  test('commentDelete of an unknown comment leaves the board untouched', () {
    final s = seed();
    final next =
        applyEvent(s, ev('commentDelete', {'item': {'id': 'cm9'}}));
    expect(next.cards, s.cards);
  });

  test('an unresolved commentDelete does not poison the delete ledger', () {
    final s = seed();
    final cardId = s.cards.values.first.id;
    const commentId = 'cm9';

    final unresolved = applyEvent(s,
        ev('commentDelete', {'item': {'id': commentId, 'cardId': 'missing'}}));
    expect(unresolved.deletedCommentIds, isEmpty);

    final addressed = applyEvent(unresolved,
        ev('commentDelete', {'item': {'id': commentId, 'cardId': cardId}}));
    expect(addressed.cards[cardId]!.commentsTotal, 0);
    expect(addressed.deletedCommentIds, contains(commentId));
  });

  test('a duplicate commentCreate or commentDelete echo moves the count once',
      () {
    final s = seed();
    final cardId = s.cards.values.first.id;
    final createItem = <String, dynamic>{
      'id': 'cm1',
      'cardId': cardId,
      'userId': 'u1',
      'text': 'hi',
    };
    final deleteItem = <String, dynamic>{'id': 'cm1', 'cardId': cardId};

    // App side first: the create response folds the comment row in and the
    // count moves once. Its socket echo and any late replay must not move it
    // again.
    final afterApp = s.copyWith(
      cards: {
        ...s.cards,
        cardId: PlankaCard.fromJson({
          ...s.cards[cardId]!.toJson(),
          'commentsTotal': 2,
        })
      },
      comments: [
        PlankaComment.fromJson(createItem),
      ],
    );
    var next = applyEvent(afterApp, ev('commentCreate', {'item': createItem}));
    next = applyEvent(next, ev('commentCreate', {'item': createItem}));
    expect(next.cards[cardId]!.commentsTotal, 2);

    // Remote side: a create and its echo move once; a delete and its echo
    // move once back.
    next = applyEvent(s, ev('commentCreate', {'item': createItem}));
    next = applyEvent(next, ev('commentCreate', {'item': createItem}));
    expect(next.cards[cardId]!.commentsTotal, 2);
    next = applyEvent(next, ev('commentDelete', {'item': deleteItem}));
    next = applyEvent(next, ev('commentDelete', {'item': deleteItem}));
    expect(next.cards[cardId]!.commentsTotal, 1);
  });

  test('commentUpdate does not move the count', () {
    final s = seed();
    final cardId = s.cards.values.first.id;
    final next = applyEvent(
        s,
        ev('commentUpdate', {
          'item': {
            'id': 'cm1',
            'cardId': cardId,
            'userId': 'u1',
            'text': 'edited',
          }
        }));
    expect(next.cards[cardId]!.commentsTotal, 1);
  });

  test('cardsUpdate bulk-upserts items', () {
    final s = seed();
    final ids = s.cards.keys.toList();
    final next = applyEvent(
        s,
        SocketEvent.parse('cardsUpdate', {
          'items': [for (final id in ids) {'id': id, 'position': 5.0}],
        }));
    for (final id in ids) {
      expect(next.cards[id]!.position, 5.0);
      expect(next.cards[id]!.name, s.cards[id]!.name);
    }
  });

  test('listClear drops that list cards, keeps others', () {
    final s = seed();
    final listId = s.columns.first.id;
    final next = applyEvent(s, ev('listClear', {'item': {'id': listId}}));
    expect(next.cardsOf(listId), isEmpty);
  });

  test('unknown event is a no-op', () {
    final s = seed();
    expect(applyEvent(s, ev('somethingNew', {'item': {'id': 'x'}})).cards,
        s.cards);
  });
}
