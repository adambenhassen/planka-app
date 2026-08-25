import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/envelope_cache.dart';
import 'package:planka_app/state/projects_state.dart';

/// A fixed current account, so the notifier's offline-cache path is used.
class _CurrentAccount extends CurrentAccountNotifier {
  @override
  Account build() => Account(
      serverUrl: 'https://planka.example.com',
      token: 'tok',
      userId: 'u1',
      displayName: 'Test');
}

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/projects_index.json').readAsStringSync())
        as Map<String, dynamic>;

/// Serves the projects fixture on GET and records every mutation call.
class _FakeApi extends PlankaApi {
  _FakeApi() : super('http://x', 'tok');
  int getCalls = 0;
  final calls = <String>[];
  final patchBodies = <String, Object?>{};

  bool failGets = false;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    getCalls++;
    if (failGets) throw ApiException(503, 'server unavailable');
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
    patchBodies[path] = body;
    return Envelope.parse({'item': <String, dynamic>{}});
  }

  @override
  Future<Envelope> delete(String path) async {
    calls.add('DELETE $path');
    return Envelope.parse({'item': <String, dynamic>{}});
  }
}

void main() {
  /// Boots with a selected account (so the offline cache path is used) and
  /// an in-memory cache directory.
  Future<(ProviderContainer, ProjectsNotifier, _FakeApi)> boot() async {
    final api = _FakeApi();
    final cacheDir =
        Directory.systemTemp.createTempSync('projects_crud_cache');
    addTearDown(() => cacheDir.deleteSync(recursive: true));
    final container = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(api),
      currentAccountProvider
          .overrideWith(() => _CurrentAccount()),
      envelopeCacheProvider
          .overrideWithValue(EnvelopeCache(directory: cacheDir)),
    ]);
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

  test('setProjectFavorite patches isFavorite then refetches', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);
    final getsBefore = api.getCalls;

    await notifier.setProjectFavorite('p1', favorite: true);

    expect(api.calls, ['PATCH /projects/p1']);
    expect(api.patchBodies['/projects/p1'], {'isFavorite': true});
    expect(api.getCalls, getsBefore + 1);
  });

  test('orderedProjects pulls favourites ahead, keeps server order', () {
    PlankaProject p(String id, {bool favorite = false}) =>
        PlankaProject(id: id, name: id, isFavorite: favorite);
    const nullFavorite = PlankaProject(id: 'x', name: 'x');
    final view = ProjectsView(projects: [
      p('a'),
      p('b', favorite: true),
      p('c'),
      p('d', favorite: true),
      nullFavorite,
    ], boards: const [], backgroundImages: const []);

    expect(view.orderedProjects.map((p) => p.id).toList(),
        ['b', 'd', 'a', 'c', 'x']);
  });

  test('a failed refresh after a successful mutation surfaces an error, '
      'never stale cached data', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    // The initial load succeeded, so the offline cache now holds a copy with
    // the pre-mutation state. The write succeeds; the refresh after it fails.
    api.failGets = true;
    // The mutation rejects with the refresh failure, so the caller can
    // surface it (guardMutation shows the snackbar).
    await expectLater(
        notifier.setProjectFavorite('p1', favorite: true),
        throwsA(isA<ApiException>()));

    expect(api.calls, ['PATCH /projects/p1']);

    final state = container.read(projectsProvider);
    expect(state.hasError, isTrue);
    // The mutation's own write succeeded, so the failure is the refresh's.
    expect(state.error, isA<ApiException>());
  });

  test('an ordinary list load still falls back to the offline cache',
      () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    api.failGets = true;
    container.invalidate(projectsProvider);

    // The fetch fails, but the last good copy is served from the cache.
    await expectLater(container.read(projectsProvider.future),
        completes);
    final state = container.read(projectsProvider);
    expect(state.hasError, isFalse);
    expect(state.value!.projects, isNotEmpty);
  });

  test('project and board mutations hit the expected endpoints', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    await notifier.renameProject('p1', 'Renamed');
    await notifier.setProjectGradient('p1', 'ocean-dive');
    await notifier.setProjectBackgroundImage('p1',
        filePath: 'test/fixtures/projects_index.json', name: 'bg.png');
    await notifier.clearProjectBackground('p1');
    await notifier.addProjectManager('p1', 'u1');
    await notifier.removeProjectManager('pm1');
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
      'POST /projects/p1/project-managers',
      'DELETE /project-managers/pm1',
      'DELETE /projects/p1',
      'POST /projects/p1/boards',
      'PATCH /boards/b1',
      'DELETE /boards/b1',
    ]);
  });
}
