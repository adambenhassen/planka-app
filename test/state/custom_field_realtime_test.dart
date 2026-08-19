import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_socket.dart';
import 'package:planka_app/state/board_state.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

const _cardId = '1844338625718780953';
const _groupId = '1844338640356901915'; // board group BG
const _cardGroupId = '1844338699437868065'; // card group CG
const _fieldId = '1844338649919915036'; // BG → F, holding "hello"
const _valueId = '1844338691242198047'; // the row holding "hello"

BoardState _seed() =>
    BoardState.fromEnvelope(Envelope.parse(_json('board_show_custom_fields')))
        .withBaseCustomFields(
            Envelope.parse(_json('project_show_custom_fields')));

SocketEvent _ev(String name, Map<String, dynamic> item) =>
    SocketEvent.parse(name, {'item': item});

void main() {
  test('customFieldValueUpdate sets a value the card did not have', () {
    final s = _seed();
    final empty = s.customFields.firstWhere((f) => f.name == 'Empty');

    final next = applyEvent(
        s,
        _ev('customFieldValueUpdate', {
          'id': 'v-new',
          'cardId': _cardId,
          'customFieldGroupId': _groupId,
          'customFieldId': empty.id,
          'content': 'from elsewhere',
        }));

    expect(next.customFieldValueOf(_cardId, _groupId, empty.id)?.content,
        'from elsewhere');
  });

  test('customFieldValueUpdate replaces the value already held', () {
    final next = applyEvent(
        _seed(),
        _ev('customFieldValueUpdate', {
          'id': _valueId,
          'cardId': _cardId,
          'customFieldGroupId': _groupId,
          'customFieldId': _fieldId,
          'content': 'world',
        }));

    expect(next.customFieldValueOf(_cardId, _groupId, _fieldId)?.content,
        'world');
    expect(next.customFieldValues.where((v) => v.customFieldId == _fieldId),
        hasLength(1));
  });

  test('customFieldValueDelete leaves the field reading as never set', () {
    final next = applyEvent(
        _seed(),
        _ev('customFieldValueDelete', {
          'id': _valueId,
          'cardId': _cardId,
          'customFieldGroupId': _groupId,
          'customFieldId': _fieldId,
          'content': 'hello',
        }));

    expect(next.customFieldValueOf(_cardId, _groupId, _fieldId), isNull);
  });

  test('customFieldGroupCreate adds a group to the open board', () {
    final s = _seed();
    final next = applyEvent(
        s,
        _ev('customFieldGroupCreate', {
          'id': 'g-new',
          'name': 'Added',
          'position': 65536,
          'boardId': s.board.id,
          'cardId': null,
          'baseCustomFieldGroupId': null,
        }));

    expect(next.customFieldGroupsOf(_cardId).map(next.customFieldGroupName),
        ['Base', 'BG', 'Added', 'CG']);
  });

  test('customFieldGroupUpdate renames a group in place', () {
    final next = applyEvent(
        _seed(),
        _ev('customFieldGroupUpdate', {
          'id': _groupId,
          'name': 'Renamed',
          'position': 32768,
          'boardId': '1844338624586318868',
          'cardId': null,
          'baseCustomFieldGroupId': null,
        }));

    expect(next.customFieldGroups.firstWhere((g) => g.id == _groupId).name,
        'Renamed');
  });

  test('a reposition keeps the group it shifts intact', () {
    // Repositioning one group broadcasts {id, position} for every sibling it
    // pushed along — a partial payload that must not blank the rest of the row.
    final next = applyEvent(
        _seed(), _ev('customFieldGroupUpdate', {'id': _groupId, 'position': 8}));

    final group = next.customFieldGroups.firstWhere((g) => g.id == _groupId);
    expect(group.name, 'BG');
    expect(group.boardId, isNotNull);
    expect(group.position, 8);
    // Its fields still belong to it, and it now sorts ahead of the based group.
    expect(next.customFieldsOf(group).map((f) => f.name),
        ['F', 'Front', 'Empty']);
    expect(next.customFieldGroupsOf(_cardId).map((g) => g.name).first, 'BG');
  });

  test('customFieldGroupDelete drops the group, its fields and its values', () {
    final next =
        applyEvent(_seed(), _ev('customFieldGroupDelete', {'id': _groupId}));

    expect(next.customFieldGroups.map((g) => g.id), isNot(contains(_groupId)));
    expect(next.customFields.map((f) => f.name), isNot(contains('F')));
    expect(next.customFieldValues.map((v) => v.content), isNot(contains('hello')));
    // Other groups keep theirs.
    expect(next.customFieldValues.map((v) => v.content), contains('card level'));
  });

  test('customFieldCreate adds a field to its group', () {
    final next = applyEvent(
        _seed(),
        _ev('customFieldCreate', {
          'id': 'f-new',
          'name': 'Added',
          'position': 65536,
          'showOnFrontOfCard': false,
          'customFieldGroupId': _groupId,
          'baseCustomFieldGroupId': null,
        }));

    final group = next.customFieldGroups.firstWhere((g) => g.id == _groupId);
    expect(next.customFieldsOf(group).map((f) => f.name),
        ['F', 'Front', 'Empty', 'Added']);
  });

  test('customFieldUpdate renames a field in place', () {
    final next = applyEvent(
        _seed(),
        _ev('customFieldUpdate', {
          'id': _fieldId,
          'name': 'Renamed',
          'position': 16384,
          'showOnFrontOfCard': false,
          'customFieldGroupId': _groupId,
          'baseCustomFieldGroupId': null,
        }));

    expect(next.customFields.firstWhere((f) => f.id == _fieldId).name,
        'Renamed');
  });

  test('a field reposition keeps the field it shifts intact', () {
    final next = applyEvent(
        _seed(), _ev('customFieldUpdate', {'id': _fieldId, 'position': 65536}));

    final group = next.customFieldGroups.firstWhere((g) => g.id == _groupId);
    expect(next.customFieldsOf(group).map((f) => f.name),
        ['Front', 'Empty', 'F']);
    // The value keyed to it is untouched by a move.
    expect(next.customFieldValueOf(_cardId, _groupId, _fieldId)?.content,
        'hello');
  });

  test('customFieldDelete drops the field and any value held for it', () {
    final next = applyEvent(_seed(), _ev('customFieldDelete', {'id': _fieldId}));

    expect(next.customFields.map((f) => f.id), isNot(contains(_fieldId)));
    expect(next.customFieldValueOf(_cardId, _groupId, _fieldId), isNull);
    expect(next.customFieldValues.map((v) => v.content), contains('on front'));
  });

  test('a card group deleted elsewhere leaves the board groups alone', () {
    final next =
        applyEvent(_seed(), _ev('customFieldGroupDelete', {'id': _cardGroupId}));

    expect(next.customFieldGroupsOf(_cardId).map(next.customFieldGroupName),
        ['Base', 'BG']);
  });

  test('an unknown custom field event leaves state untouched', () {
    final s = _seed();
    expect(identical(applyEvent(s, _ev('customFieldNudge', {'id': 'x'})), s),
        isTrue);
  });
}
