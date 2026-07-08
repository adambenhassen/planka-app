import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../api/repositories.dart';
import '../auth/auth_providers.dart';
import 'envelope_cache.dart';
import 'positions.dart';

/// The projects list plus the boards nested under them, translated out of the
/// raw API envelope so the UI consumes domain types rather than dynamic maps.
class ProjectsView {
  final List<PlankaProject> projects;
  final List<PlankaBoard> boards;
  final List<PlankaBackgroundImage> backgroundImages;
  final List<PlankaProjectManager> managers;
  final List<PlankaUser> users;
  const ProjectsView({
    required this.projects,
    required this.boards,
    required this.backgroundImages,
    this.managers = const [],
    this.users = const [],
  });

  List<PlankaProjectManager> managersOf(String projectId) =>
      managers.where((m) => m.projectId == projectId).toList();
}

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, ProjectsView>(ProjectsNotifier.new);

class ProjectsNotifier extends AsyncNotifier<ProjectsView> {
  PlankaRepo get _repo => PlankaRepo(ref.read(apiProvider));

  @override
  Future<ProjectsView> build() {
    // Re-fetch when the active account (and thus the API client) changes.
    ref.watch(apiProvider);
    return _fetch();
  }

  Future<ProjectsView> _fetch() async {
    final accountId = ref.read(currentAccountProvider)?.id;
    // Serve the last good copy when the network is down (offline read cache).
    final env = accountId == null
        ? await _repo.projects()
        : await ref
            .read(envelopeCacheProvider)
            .fetchOrCached('$accountId-projects', _repo.projects);
    return ProjectsView(
      projects: env.items.map(PlankaProject.fromJson).toList(),
      boards: env.included.boards,
      backgroundImages: env.included.backgroundImages,
      managers: env.included.projectManagers,
      users: env.included.users,
    );
  }

  // ponytail: no optimistic updates here — project/board CRUD is rare, so each
  // mutation awaits the server then refetches the (small) projects payload.
  Future<void> _mutate(Future<Object?> Function() call) async {
    await call();
    state = AsyncData(await _fetch());
  }

  Future<void> createProject(String name) =>
      _mutate(() => _repo.createProject(name));

  Future<void> renameProject(String id, String name) =>
      _mutate(() => _repo.updateProject(id, {'name': name}));

  Future<void> deleteProject(String id) =>
      _mutate(() => _repo.deleteProject(id));

  Future<void> createBoard(String projectId, String name) => _mutate(() {
        final last = (state.value?.boards ?? const [])
            .where((b) => b.projectId == projectId)
            .lastOrNull
            ?.position;
        return _repo.createBoard(projectId,
            name: name,
            position: last == null ? kPositionGap : last + kPositionGap);
      });

  Future<void> addProjectManager(String projectId, String userId) =>
      _mutate(() => _repo.addProjectManager(projectId, userId));

  Future<void> removeProjectManager(String id) =>
      _mutate(() => _repo.removeProjectManager(id));

  Future<void> setProjectGradient(String id, String gradient) =>
      _mutate(() => _repo.updateProject(
          id, {'backgroundType': 'gradient', 'backgroundGradient': gradient}));

  Future<void> setProjectBackgroundImage(String id,
          {required String filePath, required String name}) =>
      _mutate(() async {
        await _repo.uploadProjectBackgroundImage(id,
            filePath: filePath, name: name);
        return _repo.updateProject(id, {'backgroundType': 'image'});
      });

  Future<void> clearProjectBackground(String id) =>
      _mutate(() => _repo.updateProject(id, {'backgroundType': null}));

  Future<void> renameBoard(String id, String name) =>
      _mutate(() => _repo.updateBoard(id, {'name': name}));

  Future<void> deleteBoard(String id) => _mutate(() => _repo.deleteBoard(id));
}
