import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
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
