import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/board_state.dart';
import '../../state/projects_state.dart';
import '../error_handling.dart';
import 'confirm_dialog.dart';

Future<void> showProjectManagersDialog(BuildContext context, String projectId) =>
    showDialog(
      context: context,
      builder: (_) => _ProjectManagersDialog(projectId: projectId),
    );

/// Manage a project's managers: list, remove, and (admin-only) add. Watches
/// the projects provider so the list stays in sync after each mutation.
class _ProjectManagersDialog extends ConsumerWidget {
  const _ProjectManagersDialog({required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(projectsProvider).value;
    final notifier = ref.read(projectsProvider.notifier);
    if (view == null) return const SizedBox.shrink();
    final managers = view.managersOf(projectId);
    final managerUserIds = managers.map((m) => m.userId).toSet();

    PlankaUser? userOf(String id) =>
        view.users.where((u) => u.id == id).firstOrNull;

    return AlertDialog(
      title: Text(l10n.projectManagersTitle),
      content: SizedBox(
        width: 400,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final m in managers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.manage_accounts_outlined),
                title: Text(userOf(m.userId)?.name ?? l10n.unknownUser),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: l10n.projectManagerRemoveTooltip,
                  onPressed: () async {
                    final ok = await confirmDialog(context,
                        title: l10n.projectManagerRemoveTitle,
                        message: l10n.projectManagerRemoveMessage,
                        confirmLabel: l10n.actionRemove);
                    if (!ok || !context.mounted) return;
                    guardMutation(
                        context, notifier.removeProjectManager(m.id));
                  },
                ),
              ),
            const Divider(),
            _AddManager(
              managerUserIds: managerUserIds,
              onAdd: (userId) => guardMutation(
                  context, notifier.addProjectManager(projectId, userId)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionClose),
        ),
      ],
    );
  }
}

class _AddManager extends ConsumerWidget {
  const _AddManager({required this.managerUserIds, required this.onAdd});
  final Set<String> managerUserIds;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final users = ref.watch(allUsersProvider);
    return users.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator()),
      ),
      // Listing all users needs admin/project-owner rights on the server.
      error: (_, _) => Text(
        l10n.projectManagersAdminRequired,
        style: TextStyle(color: Theme.of(context).hintColor),
      ),
      data: (all) {
        final candidates =
            all.where((u) => !managerUserIds.contains(u.id)).toList();
        if (candidates.isEmpty) {
          return Text(l10n.projectManagersAllAdded,
              style: TextStyle(color: Theme.of(context).hintColor));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.projectManagerAdd,
                style: Theme.of(context).textTheme.labelLarge),
            for (final u in candidates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_add_alt),
                title: Text(u.name),
                subtitle: u.username == null ? null : Text(u.username!),
                onTap: () => onAdd(u.id),
              ),
          ],
        );
      },
    );
  }
}
