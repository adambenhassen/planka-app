import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_socket.dart';
import 'package:planka_app/state/board_state.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

const _boardId = '1844338624586318868';
const _projectId = '1844338623806178322';
const _cardId = '1844338625718780953';
const _baseGroupId = '1844338733814383652'; // project template "Base"
const _basedGroupId = '1844338760607597606'; // the board group built from it
const _baseFieldId = '1844338751229133861'; // Base → BF, holding "based"

BoardState _seed() =>
    BoardState.fromEnvelope(Envelope.parse(_json('board_show_custom_fields')))
        .withBaseCustomFields(
            Envelope.parse(_json('project_show_custom_fields')));

SocketEvent _ev(String name, Map<String, dynamic> item) =>
    SocketEvent.parse(name, {'item': item});

/// A field payload as the server sends it for a field on a base group.
Map<String, dynamic> _baseField(String id, String name, double position,
        {String baseGroupId = _baseGroupId}) =>
    {
      'id': id,
      'name': name,
      'position': position,
      'showOnFrontOfCard': false,
      'customFieldGroupId': null,
      'baseCustomFieldGroupId': baseGroupId,
    };

/// The fields the board group instantiated from the template renders.
List<String> _basedFieldNames(BoardState s) => s
    .customFieldsOf(s.customFieldGroups.firstWhere((g) => g.id == _basedGroupId))
    .map((f) => f.name)
    .toList();

void main() {
  test('a base group renamed elsewhere renames the board group built from it',
      () {
    final next = applyEvent(
        _seed(),
        _ev('baseCustomFieldGroupUpdate', {
          'id': _baseGroupId,
          'projectId': _projectId,
          'name': 'Renamed base',
        }));

    expect(next.customFieldGroupsOf(_cardId).map(next.customFieldGroupName),
        ['Renamed base', 'BG', 'CG']);
  });

  test('a field added to the base group appears on the board group', () {
    final next = applyEvent(
        _seed(), _ev('customFieldCreate', _baseField('bf-2', 'BF2', 32768)));

    expect(_basedFieldNames(next), ['BF', 'BF2']);
  });

  test('a field renamed on the base group renames it on the board group', () {
    final next = applyEvent(_seed(),
        _ev('customFieldUpdate', _baseField(_baseFieldId, 'Renamed', 16384)));

    expect(_basedFieldNames(next), ['Renamed']);
    // The value the card holds for it is keyed by id, so a rename keeps it.
    expect(next.customFieldValueOf(_cardId, _basedGroupId, _baseFieldId)?.content,
        'based');
  });

  test('a base field reposition keeps the field it shifts intact', () {
    // Reordering fields on a template broadcasts {id, position} for every
    // sibling it pushed along, exactly as the board room does.
    var s = applyEvent(
        _seed(), _ev('customFieldCreate', _baseField('bf-2', 'BF2', 32768)));
    s = applyEvent(
        s, _ev('customFieldUpdate', {'id': _baseFieldId, 'position': 65536}));

    expect(_basedFieldNames(s), ['BF2', 'BF']);
    expect(
        s.customFields
            .firstWhere((f) => f.id == _baseFieldId)
            .baseCustomFieldGroupId,
        _baseGroupId);
    expect(s.customFieldValueOf(_cardId, _basedGroupId, _baseFieldId)?.content,
        'based');
  });

  test('a field removed from the base group disappears from the board group',
      () {
    final next = applyEvent(
        _seed(), _ev('customFieldDelete', _baseField(_baseFieldId, 'BF', 16384)));

    expect(_basedFieldNames(next), isEmpty);
    expect(next.customFieldValueOf(_cardId, _basedGroupId, _baseFieldId), isNull);
    // The group still renders: it resolves to the template's name.
    expect(next.customFieldGroupsOf(_cardId).map(next.customFieldGroupName),
        ['Base', 'BG', 'CG']);
  });

  test('deleting the base group takes the board group, its fields and values',
      () {
    // The server deletes the instantiated groups itself and broadcasts nothing
    // on the board room for them, so the whole cascade has to happen here.
    final next = applyEvent(
        _seed(),
        _ev('baseCustomFieldGroupDelete', {
          'id': _baseGroupId,
          'projectId': _projectId,
          'name': 'Base',
        }));

    expect(next.customFieldGroupsOf(_cardId).map(next.customFieldGroupName),
        ['BG', 'CG']);
    expect(next.customFieldGroups.map((g) => g.id), isNot(contains(_basedGroupId)));
    expect(next.baseCustomFieldGroups, isEmpty);
    expect(next.customFields.map((f) => f.id), isNot(contains(_baseFieldId)));
    expect(next.customFieldValues.map((v) => v.content), isNot(contains('based')));
    // The board's own groups keep everything of theirs.
    expect(next.customFieldValues.map((v) => v.content),
        containsAll(['hello', 'on front', 'card level']));
    expect(next.needsBaseCustomFields, isFalse);
  });

  test('a base group created in this project is recorded for its fields', () {
    var s = applyEvent(
        _seed(),
        _ev('baseCustomFieldGroupCreate', {
          'id': 'base-2',
          'projectId': _projectId,
          'name': 'Second',
        }));
    expect(s.baseCustomFieldGroups.map((b) => b.name), ['Base', 'Second']);

    // A field on it arrives before any board group is built from it.
    s = applyEvent(s,
        _ev('customFieldCreate', _baseField('f-2', 'S1', 16384, baseGroupId: 'base-2')));
    // Instantiating it onto the open board then renders both, with no refetch.
    s = applyEvent(
        s,
        _ev('customFieldGroupCreate', {
          'id': 'g-2',
          'name': null,
          'position': 65536,
          'boardId': _boardId,
          'cardId': null,
          'baseCustomFieldGroupId': 'base-2',
        }));

    final group = s.customFieldGroups.firstWhere((g) => g.id == 'g-2');
    expect(s.customFieldGroupName(group), 'Second');
    expect(s.customFieldsOf(group).map((f) => f.name), ['S1']);
    expect(s.needsBaseCustomFields, isFalse);
  });

  test('a base group in another project leaves this board untouched', () {
    // The user room carries every project the account can see.
    final s = _seed();
    for (final name in [
      'baseCustomFieldGroupCreate',
      'baseCustomFieldGroupUpdate',
      'baseCustomFieldGroupDelete',
    ]) {
      final next = applyEvent(
          s,
          _ev(name, {
            'id': 'other-base',
            'projectId': 'other-project',
            'name': 'Theirs',
          }));
      expect(identical(next, s), isTrue, reason: name);
    }
  });

  test('a field on another project\'s base group leaves this board untouched',
      () {
    final s = _seed();
    for (final name in [
      'customFieldCreate',
      'customFieldUpdate',
      'customFieldDelete',
    ]) {
      final next = applyEvent(s,
          _ev(name, _baseField('other-f', 'Theirs', 16384, baseGroupId: 'other-base')));
      expect(identical(next, s), isTrue, reason: name);
    }
  });

  test('a reposition for a field this board never held changes nothing', () {
    // {id, position} names neither group, so an unknown id is all we have.
    final s = _seed();
    expect(
        identical(
            applyEvent(s, _ev('customFieldUpdate', {'id': 'nope', 'position': 8})),
            s),
        isTrue);
  });
}
