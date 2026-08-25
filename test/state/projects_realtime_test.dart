import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/api/planka_socket.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/state/projects_state.dart';
import 'package:planka_app/state/user_socket.dart';

SocketEvent _event(String name, Map<String, dynamic> item) =>
    SocketEvent.parse(name, {'item': item});

ProjectsView _view() => ProjectsView(
      projects: [
        const PlankaProject(
          id: 'p1',
          name: 'Project',
          backgroundType: 'gradient',
          backgroundGradient: 'ocean-dive',
          backgroundImageId: 'image-1',
        ),
      ],
      boards: [
        const PlankaBoard(id: 'b1', projectId: 'p1', name: 'Board'),
      ],
      backgroundImages: [
        const PlankaBackgroundImage(id: 'image-1', url: 'old.png'),
      ],
      managers: [
        const PlankaProjectManager(id: 'manager-1', projectId: 'p1', userId: 'u1'),
      ],
      users: [
        const PlankaUser(id: 'u1', name: 'Alice', role: 'admin'),
      ],
      baseCustomFieldGroups: [
        const PlankaBaseCustomFieldGroup(
            id: 'base-1', projectId: 'p1', name: 'Template'),
      ],
      customFields: [
        const PlankaCustomField(
          id: 'field-1',
          name: 'Field',
          baseCustomFieldGroupId: 'base-1',
        ),
      ],
    );

class _FakeApi extends PlankaApi {
  _FakeApi() : super('http://x', 'tok');

  var projectName = 'Project';
  var includeSecondProject = false;
  var getCalls = 0;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    getCalls++;
    return Envelope.parse({
      'items': [
        {'id': 'p1', 'name': projectName},
        if (includeSecondProject) {'id': 'p2', 'name': 'Second project'},
      ],
      'included': {
        'boards': [
          {'id': 'b1', 'projectId': 'p1', 'name': 'Board'},
        ],
      },
    });
  }
}

Future<(ProviderContainer, _FakeApi, StreamController<SocketEvent>,
        StreamController<bool>)>
    _boot() async {
  final api = _FakeApi();
  final events = StreamController<SocketEvent>.broadcast();
  final connected = StreamController<bool>.broadcast();
  final container = ProviderContainer(overrides: [
    apiProvider.overrideWithValue(api),
    userSocketProvider.overrideWithValue(null),
    userEventsProvider.overrideWithValue(events.stream),
    userConnectedProvider.overrideWithValue(connected.stream),
  ]);
  addTearDown(container.dispose);
  addTearDown(events.close);
  addTearDown(connected.close);
  await container.read(projectsProvider.future);
  return (container, api, events, connected);
}

void main() {
  test('project and board updates merge partial socket payloads', () {
    var view = _view();
    view = applyProjectsEvent(
        view, _event('projectUpdate', {'id': 'p1', 'name': 'Renamed'}));
    view = applyProjectsEvent(
        view, _event('boardUpdate', {'id': 'b1', 'name': 'Renamed board'}));

    expect(view.projects.single.name, 'Renamed');
    expect(view.projects.single.backgroundGradient, 'ocean-dive');
    expect(view.boards.single.name, 'Renamed board');
    expect(view.boards.single.projectId, 'p1');
  });

  test('unknown project creates do not enter state before reconciliation', () {
    final view = _view();
    final next = applyProjectsEvent(
        view, _event('projectCreate', {'id': 'foreign', 'name': 'Foreign'}));

    expect(identical(next, view), isTrue);
    expect(next.projects.map((project) => project.id), ['p1']);
  });

  test('foreign board and manager creates do not enter state', () {
    final view = _view();
    final withBoard = applyProjectsEvent(view, _event('boardCreate', {
      'id': 'foreign-board',
      'projectId': 'foreign-project',
      'name': 'Foreign board',
    }));
    final withManager = applyProjectsEvent(withBoard,
        _event('projectManagerCreate', {
          'id': 'foreign-manager',
          'projectId': 'foreign-project',
          'userId': 'u1',
        }));

    expect(identical(withBoard, view), isTrue);
    expect(identical(withManager, view), isTrue);
  });

  test('project deletion removes nested project data', () {
    final next = applyProjectsEvent(_view(), _event('projectDelete', {'id': 'p1'}));

    expect(next.projects, isEmpty);
    expect(next.boards, isEmpty);
    expect(next.managers, isEmpty);
    expect(next.baseCustomFieldGroups, isEmpty);
    expect(next.customFields, isEmpty);
    expect(next.backgroundImages, isEmpty);
  });

  test('manager, background and user events update open project surfaces', () {
    var view = _view();
    view = applyProjectsEvent(view, _event('projectManagerCreate', {
      'id': 'manager-2',
      'projectId': 'p1',
      'userId': 'u2',
    }));
    view = applyProjectsEvent(view, _event('backgroundImageDelete', {
      'id': 'image-1',
    }));
    view = applyProjectsEvent(
        view, _event('userUpdate', {'id': 'u1', 'name': 'Alice updated'}));

    expect(view.managers.map((manager) => manager.id),
        containsAll(['manager-1', 'manager-2']));
    expect(view.backgroundImages, isEmpty);
    expect(view.users.single.name, 'Alice updated');
  });

  test('all-users event fold handles create, partial update and delete', () {
    var users = [
      const PlankaUser(id: 'u1', name: 'Alice', role: 'admin'),
    ];
    users = applyUsersEvent(
        users,
        _event('userCreate',
            {'id': 'u2', 'name': 'Bob', 'role': 'boardUser'}));
    users = applyUsersEvent(
        users, _event('userUpdate', {'id': 'u1', 'name': 'Alice updated'}));
    users = applyUsersEvent(users, _event('userDelete', {'id': 'u2'}));

    expect(users.map((user) => user.id), ['u1']);
    expect(users.single.name, 'Alice updated');
    expect(users.single.role, 'admin');
  });

  test('project events reconcile from a fresh response', () async {
    final (container, api, events, _) = await _boot();
    api.includeSecondProject = true;
    events.add(_event('projectCreate', {'id': 'p2', 'name': 'Second project'}));
    await pumpEventQueue();

    expect(container.read(projectsProvider).value!.projects.map((p) => p.id),
        containsAll(['p1', 'p2']));
    expect(api.getCalls, greaterThan(1));
  });

  test('a user-room reconnect bypasses the projects cache', () async {
    final (container, api, _, connected) = await _boot();
    final before = api.getCalls;
    api.projectName = 'Renamed after reconnect';
    connected.add(true);
    await pumpEventQueue();

    expect(api.getCalls, greaterThan(before));
    expect(container.read(projectsProvider).value!.projects.single.name,
        'Renamed after reconnect');
  });
}
