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
const _baseFieldId = '1844338751229133861';
const _basedGroupId = '1844338760607597606'; // board group built from it

// The project responses the server would answer with after a change made
// elsewhere while our socket was down.
final Map<String, dynamic> _projectWithoutBaseField = () {
  final env = Map<String, dynamic>.from(_json('project_show_custom_fields'));
  final included =
      Map<String, dynamic>.from(env['included'] as Map<String, dynamic>);
  included['customFields'] = (included['customFields'] as List)
      .where((e) => (e as Map<String, dynamic>)['id'] != _baseFieldId)
      .toList();
  env['included'] = included;
  return env;
}();

final Map<String, dynamic> _projectWithoutBaseGroup = () {
  final env = Map<String, dynamic>.from(_json('project_show_custom_fields'));
  final included =
      Map<String, dynamic>.from(env['included'] as Map<String, dynamic>);
  included['customFields'] = (included['customFields'] as List)
      .where((e) =>
          (e as Map<String, dynamic>)['baseCustomFieldGroupId'] != _baseGroupId)
      .toList();
  included['baseCustomFieldGroups'] = [];
  env['included'] = included;
  return env;
}();

final Map<String, dynamic> _projectWithRenamedBase = () {
  final env = Map<String, dynamic>.from(_json('project_show_custom_fields'));
  final included =
      Map<String, dynamic>.from(env['included'] as Map<String, dynamic>);
  included['baseCustomFieldGroups'] = [
    for (final e in (included['baseCustomFieldGroups'] as List))
      if ((e as Map<String, dynamic>)['id'] == _baseGroupId)
        {...e, 'name': 'Renamed base'}
      else
        e,
  ];
  env['included'] = included;
  return env;
}();

class _FakeApi extends PlankaApi {
  _FakeApi() : super('http://x', 'tok');

  /// When set, served instead of the fixture for project paths — the shape the
  /// server answers with after a change made while our socket was down.
  Map<String, dynamic>? projectOverride;

  /// Holds every request while open, so events can land mid-load.
  Completer<void>? gate;

  int projectFetches = 0;
  int boardFetches = 0;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    final g = gate;
    if (g != null && !g.isCompleted) await g.future;
    if (path.startsWith('/projects/')) {
      projectFetches++;
      return Envelope.parse(
          projectOverride ?? _json('project_show_custom_fields'));
    }
    boardFetches++;
    return Envelope.parse(_json('board_show_custom_fields')); 
  }
}

class _AccNotifier extends CurrentAccountNotifier {
  @override
  Account build() => Account(
      serverUrl: 'http://x', token: 'tok', userId: 'u1', displayName: 'U');
}

/// The real notifier running [BoardNotifier.wireUserRoom], the exact production
/// wiring, minus the board socket a live server would need.
class _UserRoomNotifier extends BoardNotifier {
  _UserRoomNotifier(super.boardId);

  @override
  Future<BoardState> build() async {
    final foldUserRoom = wireUserRoom();
    final loaded = await load();
    return foldUserRoom(loaded);
  }
}

Future<(ProviderContainer, StreamController<SocketEvent>,
        StreamController<bool>)>
    _boot(_FakeApi api) async {
  final room = StreamController<SocketEvent>.broadcast();
  final connected = StreamController<bool>.broadcast();
  final container = ProviderContainer(overrides: [
    apiProvider.overrideWithValue(api),
    currentAccountProvider.overrideWith(_AccNotifier.new),
    userSocketProvider.overrideWithValue(null),
    userEventsProvider.overrideWithValue(room.stream),
    userConnectedProvider.overrideWithValue(connected.stream),
    boardProvider.overrideWith2(_UserRoomNotifier.new),
  ]);
  addTearDown(container.dispose);
  await container.read(boardProvider(_boardId).future);
  return (container, room, connected);
}

BoardState _stateOf(ProviderContainer c) =>
    c.read(boardProvider(_boardId)).value!;

List<String> _groupNames(BoardState s) =>
    s.customFieldGroupsOf(_cardId).map(s.customFieldGroupName).toList();

/// Pushes [event] onto the user room and lets the notifier fold it in.
Future<void> _push(StreamController<SocketEvent> room, String name,
    Map<String, dynamic> item) async {
  room.add(SocketEvent.parse(name, {'item': item}));
  await pumpEventQueue();
}

void main() {
  test('a base group renamed elsewhere reaches the open board', () async {
    final (container, room, _) =
        await _boot(_FakeApi());

    await _push(room, 'baseCustomFieldGroupUpdate',
        {'id': _baseGroupId, 'projectId': _projectId, 'name': 'Renamed base'});

    expect(_groupNames(_stateOf(container)),
        ['Renamed base', 'BG', 'CG']);
  });

  test('a field added to the base group elsewhere reaches the open board',
      () async {
    final (container, room, _) = await _boot(_FakeApi());

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

  test('an event landing while the snapshot loads is folded in, not dropped',
      () async {
    // The rename happens after the board fetch started but before it answered:
    // exactly the window where a listener attached too late loses it.
    final api = _FakeApi()..gate = Completer<void>();
    final room = StreamController<SocketEvent>.broadcast();
    addTearDown(room.close);
    final container = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(api),
      currentAccountProvider.overrideWith(_AccNotifier.new),
      userSocketProvider.overrideWithValue(null),
      userEventsProvider.overrideWithValue(room.stream),
      userConnectedProvider.overrideWithValue(const Stream.empty()),
      boardProvider.overrideWith2(_UserRoomNotifier.new),
    ]);
    addTearDown(container.dispose);
    addTearDown(room.close);

    final loading = container.read(boardProvider(_boardId).future);
    await pumpEventQueue();
    await _push(room, 'baseCustomFieldGroupUpdate',
        {'id': _baseGroupId, 'projectId': _projectId, 'name': 'Renamed base'});
    api.gate!.complete();
    await loading;

    expect(_groupNames(_stateOf(container)), ['Renamed base', 'BG', 'CG']);
  });

  test('a user-room reconnect resyncs what arrived while it was down',
      () async {
    final api = _FakeApi();
    final (container, _, connected) = await _boot(api);
    expect(_stateOf(container).customFields.map((f) => f.id),
        contains(_baseFieldId));

    api.projectOverride = _projectWithoutBaseField;
    connected.add(true);
    await pumpEventQueue();

    final s = _stateOf(container);
    expect(s.customFields.map((f) => f.id), isNot(contains(_baseFieldId)));
    // The group itself survives and still resolves its name from the template.
    expect(_groupNames(s), ['Base', 'BG', 'CG']);
  });

  test('a base group deleted during the outage cascades on resync', () async {
    // The server removed the instantiated groups and their values itself,
    // broadcasting nothing; the authoritative project response is the only
    // notice the board gets.
    final api = _FakeApi();
    final (container, _, connected) = await _boot(api);

    api.projectOverride = _projectWithoutBaseGroup;
    connected.add(true);
    await pumpEventQueue();

    final s = _stateOf(container);
    expect(_groupNames(s), ['BG', 'CG']);
    expect(s.customFieldGroups.map((g) => g.baseCustomFieldGroupId),
        isNot(contains(_baseGroupId)));
    expect(s.customFieldValueOf(_cardId, _basedGroupId, _baseFieldId), isNull);
    // The board's own groups keep everything of theirs.
    expect(s.customFieldValues.map((v) => v.content),
        containsAll(['hello', 'on front', 'card level']));
  });

  test('a room event landing mid-resync is not clobbered by an older response',
      () async {
    final api = _FakeApi();
    final (container, room, connected) = await _boot(api);

    // The rename event lands while the reconciliation fetch is in flight and
    // carries newer data than the response that eventually answers it.
    api.gate = Completer<void>();
    connected.add(true);
    await pumpEventQueue();
    await _push(room, 'baseCustomFieldGroupUpdate',
        {'id': _baseGroupId, 'projectId': _projectId, 'name': 'Renamed base'});
    api.projectOverride = _projectWithRenamedBase;
    api.gate!.complete();
    await pumpEventQueue();

    expect(_groupNames(_stateOf(container)), ['Renamed base', 'BG', 'CG']);
    // The stale first answer was discarded and fetched again, not installed.
    expect(api.projectFetches, greaterThanOrEqualTo(2));
  });

  test('another project on the same room leaves the board as it was',
      () async {
    final (container, room, _) = await _boot(_FakeApi());
    final before = _stateOf(container);

    await _push(room, 'baseCustomFieldGroupUpdate',
        {'id': 'other-base', 'projectId': 'other-project', 'name': 'Theirs'});

    expect(identical(_stateOf(container), before), isTrue);
  });

  test('the board takes only the base custom field events off the room',
      () async {
    // The same room carries notifications and the user list; those belong to
    // whoever else listens to it, not to the board.
    final (container, room, _) = await _boot(_FakeApi());
    final before = _stateOf(container);

    await _push(room, 'userUpdate', {'id': 'stranger', 'name': 'Stranger'});
    await _push(room, 'notificationCreate', {'id': 'n1', 'type': 'moveCard'});

    expect(identical(_stateOf(container), before), isTrue);
    expect(_stateOf(container).users.map((u) => u.id),
        isNot(contains('stranger')));
  });

  test('a reconnect edge landing during build resyncs after state lands',
      () async {
    // The room's socket can come back while the first snapshot is still being
    // fetched; that edge must not be lost just because no state exists yet.
    final api = _FakeApi()..gate = Completer<void>();
    final connected = StreamController<bool>.broadcast();
    addTearDown(connected.close);
    final container = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(api),
      currentAccountProvider.overrideWith(_AccNotifier.new),
      userSocketProvider.overrideWithValue(null),
      userEventsProvider.overrideWithValue(const Stream.empty()),
      userConnectedProvider.overrideWithValue(connected.stream),
      boardProvider.overrideWith2(_UserRoomNotifier.new),
    ]);
    addTearDown(container.dispose);

    final loading = container.read(boardProvider(_boardId).future);
    await pumpEventQueue();
    api.projectOverride = _projectWithoutBaseField;
    connected.add(true); // nobody is home yet: latch, don't drop
    api.gate!.complete();
    await loading;
    await pumpEventQueue();

    // One fetch from load(), one from the latched resync.
    expect(api.projectFetches, 2);
    expect(_stateOf(container).customFields.map((f) => f.id),
        isNot(contains(_baseFieldId)));
  });

  test('a user-room error heals with a refetch instead of only logging',
      () async {
    final api = _FakeApi();
    final (container, room, _) = await _boot(api);
    final boardsBefore = api.boardFetches;

    room.addError(StateError('user subscribe failed'));
    await pumpEventQueue();

    expect(api.boardFetches, greaterThan(boardsBefore));
    expect(_groupNames(_stateOf(container)), ['Base', 'BG', 'CG']);
  });

  test('closing the board leaves no listener on the shared room', () async {
    final (container, room, connected) = await _boot(_FakeApi());
    expect(room.hasListener, isTrue);
    expect(connected.hasListener, isTrue);

    container.dispose();
    await pumpEventQueue();

    expect(room.hasListener, isFalse);
    expect(connected.hasListener, isFalse);
  });
}
