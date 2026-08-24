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

  /// The projects' custom field templates and the fields on them. Only the
  /// projects response carries these.
  final List<PlankaBaseCustomFieldGroup> baseCustomFieldGroups;
  final List<PlankaCustomField> customFields;
  const ProjectsView({
    required this.projects,
    required this.boards,
    required this.backgroundImages,
    this.managers = const [],
    this.users = const [],
    this.baseCustomFieldGroups = const [],
    this.customFields = const [],
  });

  List<PlankaProjectManager> managersOf(String projectId) =>
      managers.where((m) => m.projectId == projectId).toList();

  /// Projects with favourites pulled ahead of the rest. Server order is kept
  /// within each group, so a user with no favourites sees exactly the order
  /// the server sent.
  List<PlankaProject> get orderedProjects {
    final favorites = <PlankaProject>[];
    final rest = <PlankaProject>[];
    for (final p in projects) {
      ((p.isFavorite ?? false) ? favorites : rest).add(p);
    }
    return [...favorites, ...rest];
  }

  /// A project's templates in server order. A base group carries no position,
  /// so there is no order to change — the list is never re-sorted.
  List<PlankaBaseCustomFieldGroup> baseGroupsOf(String projectId) =>
      baseCustomFieldGroups.where((b) => b.projectId == projectId).toList();

  /// The fields a template holds, in the server's position order.
  List<PlankaCustomField> fieldsOfBaseGroup(String baseGroupId) =>
      customFields
          .where((f) => f.baseCustomFieldGroupId == baseGroupId)
          .toList()
        ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
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
      baseCustomFieldGroups: env.included.baseCustomFieldGroups,
      customFields: env.included.customFields,
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

  Future<void> setProjectFavorite(String id, {required bool favorite}) =>
      _mutate(() => _repo.updateProject(id, {'isFavorite': favorite}));

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

  // --------------- Custom field template mutations ---------------
  // Each awaits the server then refetches the projects payload, like every
  // other mutation above. Deletes fire only after the sheet's confirmation
  // has resolved true — nothing here is ever sent optimistically.

  Future<void> createTemplate(String projectId, String name) =>
      _mutate(() => _repo.createBaseCustomFieldGroup(projectId, name: name));

  Future<void> renameTemplate(String id, String name) =>
      _mutate(() => _repo.updateBaseCustomFieldGroup(id, {'name': name}));

  Future<void> deleteTemplate(String id) =>
      _mutate(() => _repo.deleteBaseCustomFieldGroup(id));

  Future<void> createTemplateField(String templateId, String name) {
    final last = state.value?.fieldsOfBaseGroup(templateId).lastOrNull?.position;
    return _mutate(() => _repo.createBaseCustomField(templateId,
        name: name, position: positionBetween(last, null)));
  }

  Future<void> renameTemplateField(String id, String name) =>
      _mutate(() => _repo.updateCustomField(id, {'name': name}));

  Future<void> toggleTemplateFieldFrontOfCard(String id, bool show) =>
      _mutate(() => _repo.updateCustomField(id, {'showOnFrontOfCard': show}));

  Future<void> deleteTemplateField(String id) =>
      _mutate(() => _repo.deleteCustomField(id));

  Future<void> moveTemplateFieldUp(String id) =>
      _moveTemplateField(id, up: true);

  Future<void> moveTemplateFieldDown(String id) =>
      _moveTemplateField(id, up: false);

  Future<void> _moveTemplateField(String id, {required bool up}) async {
    final view = state.value;
    final field = view?.customFields.where((f) => f.id == id).firstOrNull;
    final templateId = field?.baseCustomFieldGroupId;
    if (view == null || field == null || templateId == null) return;
    final peers = view.fieldsOfBaseGroup(templateId);
    final idx = peers.indexWhere((f) => f.id == id);
    if (idx < 0) return;
    final double? position;
    if (up) {
      if (idx == 0) return;
      position = positionBetween(
          idx > 1 ? peers[idx - 2].position : null, peers[idx - 1].position);
    } else {
      if (idx >= peers.length - 1) return;
      position = positionBetween(peers[idx + 1].position,
          idx + 2 < peers.length ? peers[idx + 2].position : null);
    }
    await _mutate(
        () => _repo.updateCustomField(id, {'position': position}));
  }
}
