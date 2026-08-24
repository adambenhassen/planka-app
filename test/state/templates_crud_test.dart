import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/state/projects_state.dart';

const _projectId = 'p1';

/// A projects payload carrying two templates, Alpha with three fields.
Map<String, dynamic> _projectsEnvelope() => {
      'items': [
        {'id': _projectId, 'name': 'Proj'},
      ],
      'included': {
        'boards': [],
        'backgroundImages': [],
        'projectManagers': [],
        'users': [],
        'baseCustomFieldGroups': [
          {'id': 't1', 'projectId': _projectId, 'name': 'Alpha'},
          {'id': 't2', 'projectId': _projectId, 'name': 'Beta'},
        ],
        'customFields': [
          {
            'id': 'f1',
            'name': 'F1',
            'customFieldGroupId': null,
            'baseCustomFieldGroupId': 't1',
            'position': 16384,
            'showOnFrontOfCard': false,
          },
          {
            'id': 'f2',
            'name': 'F2',
            'customFieldGroupId': null,
            'baseCustomFieldGroupId': 't1',
            'position': 32768,
            'showOnFrontOfCard': false,
          },
          {
            'id': 'f3',
            'name': 'F3',
            'customFieldGroupId': null,
            'baseCustomFieldGroupId': 't1',
            'position': 49152,
            'showOnFrontOfCard': false,
          },
        ],
      },
    };

class _AccNotifier extends CurrentAccountNotifier {
  @override
  Account build() => Account(
      serverUrl: 'http://x', token: 'tok', userId: 'u1', displayName: 'U');
}

/// Serves the synthetic projects envelope on GET and records every mutation.
class _FakeApi extends PlankaApi {
  _FakeApi() : super('http://x', 'tok');
  int getCalls = 0;
  final calls = <(String, String, Object?)>[];

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    getCalls++;
    return Envelope.parse(_projectsEnvelope());
  }

  @override
  Future<Envelope> post(String path, Object? body) async {
    calls.add(('POST', path, body));
    return Envelope.parse({'item': <String, dynamic>{}});
  }

  @override
  Future<Envelope> patch(String path, Object? body) async {
    calls.add(('PATCH', path, body));
    return Envelope.parse({'item': <String, dynamic>{}});
  }

  @override
  Future<Envelope> delete(String path) async {
    calls.add(('DELETE', path, null));
    return Envelope.parse({'item': <String, dynamic>{}});
  }
}

void main() {
  Future<(ProviderContainer, ProjectsNotifier, _FakeApi)> boot() async {
    final api = _FakeApi();
    final container =
        ProviderContainer(overrides: [apiProvider.overrideWithValue(api)]);
    await container.read(projectsProvider.future);
    return (container, container.read(projectsProvider.notifier), api);
  }

  test('createTemplate posts to the project base-group endpoint and refetches',
      () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);
    final getsBefore = api.getCalls;

    await notifier.createTemplate(_projectId, 'Sizes');

    final call = api.calls.single;
    expect((call.$1, call.$2), ('POST', '/projects/p1/base-custom-field-groups'));
    expect(call.$3, {'name': 'Sizes'});
    expect(api.getCalls, getsBefore + 1);
  });

  test('template rename and delete hit the base-group endpoints', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    await notifier.renameTemplate('t1', 'Renamed');
    await notifier.deleteTemplate('t1');

    expect((api.calls[0].$1, api.calls[0].$2),
        ('PATCH', '/base-custom-field-groups/t1'));
    expect(api.calls[0].$3, {'name': 'Renamed'});
    expect((api.calls[1].$1, api.calls[1].$2),
        ('DELETE', '/base-custom-field-groups/t1'));
  });

  test('createTemplateField appends after the template\'s last field',
      () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    await notifier.createTemplateField('t1', 'F4');

    final call = api.calls.single;
    expect((call.$1, call.$2),
        ('POST', '/base-custom-field-groups/t1/custom-fields'));
    expect(call.$3, {'name': 'F4', 'position': 65536.0});
  });

  test('moving a template field down lands it between its neighbours',
      () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    await notifier.moveTemplateFieldDown('f1');

    // Midpoint between F2 (32768) and F3 (49152).
    expect(api.calls.single.$1, 'PATCH');
    expect(api.calls.single.$2, '/custom-fields/f1');
    expect((api.calls.single.$3 as Map)['position'], 40960.0);
  });

  test('moving a template field up lands it between its neighbours',
      () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    await notifier.moveTemplateFieldUp('f3');

    expect(api.calls.single.$2, '/custom-fields/f3');
    // Midpoint between F1 (16384) and F2 (32768).
    expect((api.calls.single.$3 as Map)['position'], 24576.0);
  });

  test('template field rename, front toggle and delete reuse the field '
      'endpoints', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    await notifier.renameTemplateField('f1', 'Renamed');
    await notifier.toggleTemplateFieldFrontOfCard('f1', true);
    await notifier.deleteTemplateField('f1');

    expect((api.calls[0].$1, api.calls[0].$2), ('PATCH', '/custom-fields/f1'));
    expect(api.calls[0].$3, {'name': 'Renamed'});
    expect((api.calls[1].$1, api.calls[1].$2), ('PATCH', '/custom-fields/f1'));
    expect(api.calls[1].$3, {'showOnFrontOfCard': true});
    expect((api.calls[2].$1, api.calls[2].$2), ('DELETE', '/custom-fields/f1'));
  });

  test('instantiateTemplateOnBoard posts the base group id at the end and '
      'fills the group from the template', () async {
    final api = _BoardFakeApi();
    final container = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(api),
      currentAccountProvider.overrideWith(_AccNotifier.new),
      boardProvider.overrideWith2((arg) => _SocketlessNotifier(arg)),
    ]);
    addTearDown(container.dispose);
    await container.read(boardProvider(_boardId).future);
    api.calls.clear();
    final notifier = container.read(boardProvider(_boardId).notifier);

    await notifier.instantiateTemplateOnBoard(_baseGroupId);

    final write = api.calls.where((c) => c.$1 == 'POST').single;
    expect(write.$2, '/boards/$_boardId/custom-field-groups');
    // After the last board group (32768): one gap further.
    expect(write.$3,
        {'baseCustomFieldGroupId': _baseGroupId, 'position': 49152});

    final state = container.read(boardProvider(_boardId)).value!;
    final group =
        state.customFieldGroups.where((g) => g.id == 'new-group').firstOrNull;
    expect(group?.baseCustomFieldGroupId, _baseGroupId);
  });
}

// ── Instantiating a template onto a board ────────────────────────────────

const _boardId = '1844338624586318868';
const _baseGroupId = '1844338733814383652';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// Serves the recorded board/project fixtures on GET and records mutations.
class _BoardFakeApi extends PlankaApi {
  _BoardFakeApi() : super('http://x', 'tok');
  final calls = <(String, String, Object?)>[];

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    calls.add(('GET', path, null));
    return Envelope.parse(_json(path.startsWith('/projects/')
        ? 'project_show_custom_fields'
        : 'board_show_custom_fields'));
  }

  @override
  Future<Envelope> post(String path, Object? body) async {
    calls.add(('POST', path, body));
    return Envelope.parse({
      'item': {
        'id': 'new-group',
        'boardId': _boardId,
        'cardId': null,
        'baseCustomFieldGroupId': (body as Map)['baseCustomFieldGroupId'],
        'position': body['position'],
      }
    });
  }
}

class _SocketlessNotifier extends BoardNotifier {
  _SocketlessNotifier(super.boardId);
  @override
  Future<BoardState> build() => load();
}
