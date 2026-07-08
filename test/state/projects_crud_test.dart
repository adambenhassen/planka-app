import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/projects_state.dart';

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/projects_index.json').readAsStringSync())
        as Map<String, dynamic>;

/// Serves the projects fixture on GET and records every mutation call.
class _FakeApi extends PlankaApi {
  _FakeApi() : super('http://x', 'tok');
  int getCalls = 0;
  final calls = <String>[];

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    getCalls++;
    return Envelope.parse(_fixture());
  }

  @override
  Future<Envelope> post(String path, Object? body) async {
    calls.add('POST $path');
    return Envelope.parse({'item': <String, dynamic>{}});
  }

  @override
  Future<Envelope> patch(String path, Object? body) async {
    calls.add('PATCH $path');
    return Envelope.parse({'item': <String, dynamic>{}});
  }

  @override
  Future<Envelope> delete(String path) async {
    calls.add('DELETE $path');
    return Envelope.parse({'item': <String, dynamic>{}});
  }
}

void main() {
  Future<(ProviderContainer, ProjectsNotifier, _FakeApi)> boot() async {
    final api = _FakeApi();
    final container = ProviderContainer(
        overrides: [apiProvider.overrideWithValue(api)]);
    await container.read(projectsProvider.future);
    return (container, container.read(projectsProvider.notifier), api);
  }

  test('createProject posts then refetches the projects list', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);
    final getsBefore = api.getCalls;

    await notifier.createProject('New Project');

    expect(api.calls, ['POST /projects']);
    expect(api.getCalls, getsBefore + 1);
  });

  test('project and board mutations hit the expected endpoints', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    await notifier.renameProject('p1', 'Renamed');
    await notifier.setProjectGradient('p1', 'ocean-dive');
    await notifier.setProjectBackgroundImage('p1',
        filePath: 'test/fixtures/projects_index.json', name: 'bg.png');
    await notifier.clearProjectBackground('p1');
    await notifier.deleteProject('p1');
    await notifier.createBoard('p1', 'Board');
    await notifier.renameBoard('b1', 'Renamed');
    await notifier.deleteBoard('b1');

    expect(api.calls, [
      'PATCH /projects/p1',
      'PATCH /projects/p1',
      'POST /projects/p1/background-images',
      'PATCH /projects/p1',
      'PATCH /projects/p1',
      'DELETE /projects/p1',
      'POST /projects/p1/boards',
      'PATCH /boards/b1',
      'DELETE /boards/b1',
    ]);
  });
}
