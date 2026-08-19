import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/api/planka_socket.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

const _boardId = '1844338624586318868';
const _cardId = '1844338625718780953';
// Board group BG, whose field F holds "hello" and whose field Empty holds none.
const _groupId = '1844338640356901915';
const _valuePath =
    '/cards/$_cardId/custom-field-values/customFieldGroupId:$_groupId:customFieldId:';
const _baseGroupId = '1844338733814383652';

String _fieldIdOf(String name) => ((_json('board_show_custom_fields')['included']
        as Map)['customFields'] as List)
    .cast<Map<String, dynamic>>()
    .firstWhere((f) => f['name'] == name)['id'] as String;

/// Records every request and serves the untouched fixtures on GET, so a heal
/// after a rejected write is served the server's own truth.
class _FakeApi extends PlankaApi {
  _FakeApi({required this.boardFixture, this.failWrite = false})
      : super('http://x', 'tok');

  final String boardFixture;

  /// Rejects the value write the way a viewer-role account is rejected.
  final bool failWrite;

  /// method, path, body — in call order.
  final List<(String, String, Object?)> calls = [];

  /// Held open while set, so a request can be observed mid-flight.
  Completer<void>? gate;

  Iterable<(String, String, Object?)> get writes =>
      calls.where((c) => c.$1 != 'GET');

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    calls.add(('GET', path, null));
    return Envelope.parse(_json(path.startsWith('/projects/')
        ? 'project_show_custom_fields'
        : boardFixture));
  }

  @override
  Future<Envelope> patch(String path, Object? body) async {
    calls.add(('PATCH', path, body));
    await gate?.future;
    if (failWrite) throw ApiException(403, 'not enough rights');
    return Envelope.parse({
      'item': {
        'id': 'srv-value',
        'cardId': _cardId,
        'customFieldGroupId': _groupId,
        'customFieldId': path.split('customFieldId:').last,
        'content': (body as Map)['content'],
      }
    });
  }

  @override
  Future<Envelope> delete(String path) async {
    calls.add(('DELETE', path, null));
    await gate?.future;
    if (failWrite) throw ApiException(403, 'not enough rights');
    return Envelope.parse(const {'item': {}});
  }
}

class _AccNotifier extends CurrentAccountNotifier {
  @override
  Account build() => Account(
      serverUrl: 'http://x', token: 'tok', userId: 'u1', displayName: 'U');
}

/// The real notifier, seeded through the real load path but without a socket.
class _SocketlessNotifier extends BoardNotifier {
  _SocketlessNotifier(super.boardId);
  @override
  Future<BoardState> build() => load();
}

Future<(ProviderContainer, BoardNotifier, _FakeApi)> _boot(
    {String boardFixture = 'board_show_custom_fields',
    bool failWrite = false}) async {
  final api = _FakeApi(boardFixture: boardFixture, failWrite: failWrite);
  final container = ProviderContainer(overrides: [
    apiProvider.overrideWithValue(api),
    currentAccountProvider.overrideWith(_AccNotifier.new),
    boardProvider.overrideWith2(_SocketlessNotifier.new),
  ]);
  final boardId = _json(boardFixture)['item']['id'] as String;
  await container.read(boardProvider(boardId).future);
  api.calls.clear();
  return (container, container.read(boardProvider(boardId).notifier), api);
}

BoardState _stateOf(ProviderContainer c, [String boardId = _boardId]) =>
    c.read(boardProvider(boardId)).value!;

void main() {
  test('setting a value writes to the (group, field) pair and shows it at once',
      () async {
    final (container, notifier, api) = await _boot();
    addTearDown(container.dispose);
    final f = _fieldIdOf('F');

    await notifier.setCustomFieldValue(_cardId,
        groupId: _groupId, fieldId: f, content: 'world');

    final write = api.writes.single;
    expect((write.$1, write.$2), ('PATCH', '$_valuePath$f'));
    expect(write.$3, {'content': 'world'});
    expect(_stateOf(container).customFieldValueOf(_cardId, _groupId, f)?.content,
        'world');
  });

  test('a value set on a field that had none ends up as the server\'s row',
      () async {
    final (container, notifier, api) = await _boot();
    addTearDown(container.dispose);
    final empty = _fieldIdOf('Empty');

    await notifier.setCustomFieldValue(_cardId,
        groupId: _groupId, fieldId: empty, content: 'now set');

    expect(api.writes.single.$2, '$_valuePath$empty');
    final values = _stateOf(container)
        .customFieldValues
        .where((v) => v.customFieldId == empty);
    // One row, carrying the id the server assigned — not the placeholder the
    // optimistic write inserted.
    expect(values.map((v) => (v.id, v.content)), [('srv-value', 'now set')]);
  });

  test('the socket echo of a value still in flight leaves a single row',
      () async {
    final (container, notifier, api) = await _boot();
    addTearDown(container.dispose);
    final empty = _fieldIdOf('Empty');
    api.gate = Completer<void>();

    final pending = notifier.setCustomFieldValue(_cardId,
        groupId: _groupId, fieldId: empty, content: 'now set');
    await pumpEventQueue();
    // The server's own broadcast lands before its response does: same value,
    // real id, against the placeholder row the optimistic write inserted.
    notifier.applySocketEvent(SocketEvent.parse('customFieldValueUpdate', {
      'item': {
        'id': 'srv-value',
        'cardId': _cardId,
        'customFieldGroupId': _groupId,
        'customFieldId': empty,
        'content': 'now set',
      }
    }));
    api.gate!.complete();
    await pending;

    expect(
        _stateOf(container)
            .customFieldValues
            .where((v) => v.customFieldId == empty)
            .map((v) => v.id),
        ['srv-value']);
  });

  test('an empty value clears the row rather than storing it', () async {
    final (container, notifier, api) = await _boot();
    addTearDown(container.dispose);
    final f = _fieldIdOf('F');

    await notifier.setCustomFieldValue(_cardId,
        groupId: _groupId, fieldId: f, content: '   ');

    expect(api.writes, [('DELETE', '$_valuePath$f', null)]);
    // A cleared field reads exactly like one that was never set.
    expect(_stateOf(container).customFieldValueOf(_cardId, _groupId, f), isNull);
  });

  test('clearing a field that holds no value makes no request', () async {
    final (container, notifier, api) = await _boot();
    addTearDown(container.dispose);

    await notifier.clearCustomFieldValue(_cardId,
        groupId: _groupId, fieldId: _fieldIdOf('Empty'));

    // The server answers a delete of a value that was never set with a 404.
    expect(api.calls, isEmpty);
  });

  test('a rejected edit heals back to the server\'s value and rethrows',
      () async {
    final (container, notifier, api) = await _boot(failWrite: true);
    addTearDown(container.dispose);
    final f = _fieldIdOf('F');

    await expectLater(
        notifier.setCustomFieldValue(_cardId,
            groupId: _groupId, fieldId: f, content: 'world'),
        throwsA(isA<ApiException>()));

    expect(api.calls.any((c) => c.$1 == 'GET' && c.$2 == '/boards/$_boardId'),
        isTrue,
        reason: 'heals from the server rather than from a snapshot');
    expect(_stateOf(container).customFieldValueOf(_cardId, _groupId, f)?.content,
        'hello');
  });

  test('a rejected clear leaves the value in place', () async {
    final (container, notifier, api) = await _boot(failWrite: true);
    addTearDown(container.dispose);
    final f = _fieldIdOf('F');

    await expectLater(
        notifier.clearCustomFieldValue(_cardId, groupId: _groupId, fieldId: f),
        throwsA(isA<ApiException>()));

    expect(_stateOf(container).customFieldValueOf(_cardId, _groupId, f)?.content,
        'hello');
    expect(api.calls.first, ('DELETE', '$_valuePath$f', null));
  });

  test('a group instantiated elsewhere is named from a single project read',
      () async {
    // A board that carried no custom fields at all, so nothing about the
    // project's base groups is known when the group arrives.
    final (container, notifier, api) = await _boot(boardFixture: 'board_show');
    addTearDown(container.dispose);
    final boardId = _json('board_show')['item']['id'] as String;

    notifier.applySocketEvent(SocketEvent.parse('customFieldGroupCreate', {
      'item': {
        'id': 'g-new',
        'position': 16384,
        'name': null,
        'boardId': boardId,
        'cardId': null,
        'baseCustomFieldGroupId': _baseGroupId,
      }
    }));
    await pumpEventQueue();

    final s = _stateOf(container, boardId);
    final group = s.customFieldGroups.firstWhere((g) => g.id == 'g-new');
    expect(s.customFieldGroupName(group), 'Base');
    expect(s.customFieldsOf(group).map((f) => f.name), ['BF']);
    expect(api.calls.where((c) => c.$2.startsWith('/projects/')), hasLength(1));
  });
}
