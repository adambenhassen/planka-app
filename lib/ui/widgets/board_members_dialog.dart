import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/board_state.dart';
import '../error_handling.dart';
import 'confirm_dialog.dart';

Future<void> showBoardMembersDialog(BuildContext context, String boardId) =>
    showDialog(
      context: context,
      builder: (_) => _BoardMembersDialog(boardId: boardId),
    );

/// Manage board memberships: role toggle, remove, and (admin-only) add.
/// Watches the board provider directly, so socket echoes and optimistic
/// updates keep the dialog in sync while it stays open.
class _BoardMembersDialog extends ConsumerWidget {
  const _BoardMembersDialog({required this.boardId});
  final String boardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(boardProvider(boardId)).value;
    final notifier = ref.read(boardProvider(boardId).notifier);
    if (state == null) return const SizedBox.shrink();
    final memberIds = state.boardMemberships.map((m) => m.userId).toSet();
    return AlertDialog(
      title: const Text('Board members'),
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
                    'Unknown'),
                subtitle: Text(m.role),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) async {
                    if (action == 'remove') {
                      final ok = await confirmDialog(context,
                          title: 'Remove member?',
                          message:
                              'They will lose access to this board.',
                          confirmLabel: 'Remove');
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
                            ? 'Make viewer'
                            : 'Make editor')),
                    const PopupMenuItem(
                        value: 'remove', child: Text('Remove')),
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
          child: const Text('Close'),
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
    final users = ref.watch(allUsersProvider);
    return users.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator()),
      ),
      // Listing all users needs admin/project-owner rights on the server.
      error: (_, _) => Text(
        'Adding members requires admin rights',
        style: TextStyle(color: Theme.of(context).hintColor),
      ),
      data: (all) {
        final candidates =
            all.where((u) => !memberIds.contains(u.id)).toList();
        if (candidates.isEmpty) {
          return Text('Everyone is already a member',
              style: TextStyle(color: Theme.of(context).hintColor));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add member',
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
