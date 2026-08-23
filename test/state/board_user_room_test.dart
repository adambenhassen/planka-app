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
import 'package:planka_app/state/user_socket.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

const _boardId = '1844338624586318868';
const _projectId = '1844338623806178322';
const _cardId = '1844338625718780953';
const _baseGroupId = '1844338733814383652';

class _FakeApi extends PlankaApi {
  _FakeApi() : super('http://x', 'tok');

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async =>
      Envelope.parse(_json(path.startsWith('/projects/')
          ? 'project_show_custom_fields'
          : 'board_show_custom_fields'));
}

class _AccNotifier extends CurrentAccountNotifier {
  @override
  Account build() => Account(
      serverUrl: 'http://x', token: 'tok', userId: 'u1', displayName: 'U');
}

/// The real notifier wired to the user room the same way [BoardNotifier.build]
/// wires it, but without the board socket a live server would need.
class _UserRoomNotifier extends BoardNotifier {
  _UserRoomNotifier(super.boardId);

  @override
  Future<BoardState> build() async {
    final userEvents = ref.watch(userEventsProvider);
    final loaded = await load();
    listenToUserRoom(userEvents);
    return loaded;
  }
}

Future<(ProviderContainer, StreamController<SocketEvent>)> _boot() async {
  final userRoom = StreamController<SocketEvent>.broadcast();
  final container = ProviderContainer(overrides: [
    apiProvider.overrideWithValue(_FakeApi()),
    currentAccountProvider.overrideWith(_AccNotifier.new),
    userEventsProvider.overrideWithValue(userRoom.stream),
    boardProvider.overrideWith2(_UserRoomNotifier.new),
  ]);
  await container.read(boardProvider(_boardId).future);
  return (container, userRoom);
}

BoardState _stateOf(ProviderContainer c) =>
    c.read(boardProvider(_boardId)).value!;

/// Pushes [event] onto the user room and lets the notifier fold it in.
Future<void> _push(StreamController<SocketEvent> room, String name,
    Map<String, dynamic> item) async {
  room.add(SocketEvent.parse(name, {'item': item}));
  await pumpEventQueue();
}

void main() {
  test('a base group renamed elsewhere reaches the open board', () async {
    final (container, room) = await _boot();
    addTearDown(container.dispose);

    await _push(room, 'baseCustomFieldGroupUpdate',
        {'id': _baseGroupId, 'projectId': _projectId, 'name': 'Renamed base'});

    final s = _stateOf(container);
    expect(s.customFieldGroupsOf(_cardId).map(s.customFieldGroupName),
        ['Renamed base', 'BG', 'CG']);
  });

  test('a field added to the base group elsewhere reaches the open board',
      () async {
    final (container, room) = await _boot();
    addTearDown(container.dispose);

    await _push(room, 'customFieldCreate', {
      'id': 'bf-2',
      'name': 'BF2',
      'position': 32768,
      'showOnFrontOfCard': false,
      'customFieldGroupId': null,
      'baseCustomFieldGroupId': _baseGroupId,
    });

    final s = _stateOf(container);
    final group = s.customFieldGroups
        .firstWhere((g) => g.baseCustomFieldGroupId == _baseGroupId);
    expect(s.customFieldsOf(group).map((f) => f.name), ['BF', 'BF2']);
  });

  test('another project on the same room leaves the board as it was', () async {
    final (container, room) = await _boot();
    addTearDown(container.dispose);
    final before = _stateOf(container);

    await _push(room, 'baseCustomFieldGroupUpdate',
        {'id': 'other-base', 'projectId': 'other-project', 'name': 'Theirs'});

    expect(identical(_stateOf(container), before), isTrue);
  });

  test('the board takes only the base custom field events off the room',
      () async {
    // The same room carries notifications and the user list; those belong to
    // whoever else listens to it, not to the board.
    final (container, room) = await _boot();
    addTearDown(container.dispose);
    final before = _stateOf(container);

    await _push(room, 'userUpdate', {'id': 'stranger', 'name': 'Stranger'});
    await _push(room, 'notificationCreate', {'id': 'n1', 'type': 'moveCard'});

    expect(identical(_stateOf(container), before), isTrue);
    expect(_stateOf(container).users.map((u) => u.id),
        isNot(contains('stranger')));
  });

  test('closing the board leaves no listener on the shared room', () async {
    final (container, room) = await _boot();
    expect(room.hasListener, isTrue);

    container.dispose();

    expect(room.hasListener, isFalse);
  });
}
