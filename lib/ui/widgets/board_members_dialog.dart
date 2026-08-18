import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../state/board_state.dart';
import '../error_handling.dart';
import 'confirm_dialog.dart';

Future<void> showBoardMembersDialog(BuildContext context, String boardId) =>
    showDialog(
      context: context,
      builder: (_) => _BoardMembersDialog(boardId: boardId),
    );

/// Display name for a board membership role; unknown roles from a newer
/// server fall back to the raw value.
String _roleLabel(AppLocalizations l10n, String role) => switch (role) {
      'editor' => l10n.boardRoleEditor,
      'viewer' => l10n.boardRoleViewer,
      _ => role,
    };

/// Manage board memberships: role toggle, remove, and (admin-only) add.
/// Watches the board provider directly, so socket echoes and optimistic
/// updates keep the dialog in sync while it stays open.
class _BoardMembersDialog extends ConsumerWidget {
  const _BoardMembersDialog({required this.boardId});
  final String boardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(boardProvider(boardId)).value;
    final notifier = ref.read(boardProvider(boardId).notifier);
    if (state == null) return const SizedBox.shrink();
    final memberIds = state.boardMemberships.map((m) => m.userId).toSet();
    return AlertDialog(
      title: Text(l10n.boardMembersTitle),
      content: SizedBox(
        width: 400,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final m in state.boardMemberships)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(state.users
                        .where((u) => u.id == m.userId)
                        .firstOrNull
                        ?.name ??
                    l10n.unknownUser),
                subtitle: Text(_roleLabel(l10n, m.role)),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) async {
                    if (action == 'remove') {
                      final ok = await confirmDialog(context,
                          title: l10n.boardMemberRemoveTitle,
                          message: l10n.boardMemberRemoveMessage,
                          confirmLabel: l10n.actionRemove);
                      if (!ok || !context.mounted) return;
                      guardMutation(context, notifier.removeBoardMember(m.id));
                    } else {
                      guardMutation(
                          context, notifier.setBoardMemberRole(m.id, action));
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: m.role == 'editor' ? 'viewer' : 'editor',
                        child: Text(m.role == 'editor'
                            ? l10n.boardMemberMakeViewer
                            : l10n.boardMemberMakeEditor)),
                    PopupMenuItem(
                        value: 'remove', child: Text(l10n.actionRemove)),
                  ],
                ),
              ),
            const Divider(),
            _AddMember(
              memberIds: memberIds,
              onAdd: (userId) =>
                  guardMutation(context, notifier.addBoardMember(userId)),
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

class _AddMember extends ConsumerWidget {
  const _AddMember({required this.memberIds, required this.onAdd});
  final Set<String> memberIds;
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
        l10n.boardMembersAdminRequired,
        style: TextStyle(color: Theme.of(context).hintColor),
      ),
      data: (all) {
        final candidates =
            all.where((u) => !memberIds.contains(u.id)).toList();
        if (candidates.isEmpty) {
          return Text(l10n.boardMembersAllAdded,
              style: TextStyle(color: Theme.of(context).hintColor));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.boardMemberAdd,
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
