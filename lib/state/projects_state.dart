import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../api/repositories.dart';
import '../auth/auth_providers.dart';

/// The projects list plus the boards nested under them, translated out of the
/// raw API envelope so the UI consumes domain types rather than dynamic maps.
class ProjectsView {
  final List<PlankaProject> projects;
  final List<PlankaBoard> boards;
  const ProjectsView({required this.projects, required this.boards});
}

final projectsProvider = FutureProvider<ProjectsView>((ref) async {
  final env = await PlankaRepo(ref.watch(apiProvider)).projects();
  return ProjectsView(
    projects: env.items.map(PlankaProject.fromJson).toList(),
    boards: env.included.boards,
  );
});
