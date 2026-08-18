import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models.dart';
import '../../api/repositories.dart';
import '../../auth/auth_providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/current_user_state.dart';
import '../error_handling.dart';
import 'confirm_dialog.dart';

const _roles = ['admin', 'projectOwner', 'boardUser'];

/// Display name for a Planka user role; a role from a newer server that this
/// client doesn't know falls back to the raw value.
String _roleLabel(AppLocalizations l10n, String role) => switch (role) {
      'admin' => l10n.userRoleAdmin,
      'projectOwner' => l10n.userRoleProjectOwner,
      'boardUser' => l10n.userRoleBoardUser,
      _ => role,
    };

Future<void> showUserManagementDialog(BuildContext context) => showDialog(
      context: context,
      builder: (_) => const _UserManagementDialog(),
    );

/// Admin-only user management: list all users, change role, deactivate/
/// reactivate, delete, and add new users. There's no socket feed for the
/// users list, so this refetches after every mutation (same fetch-on-open
/// pattern as project_managers_dialog).
class _UserManagementDialog extends ConsumerStatefulWidget {
  const _UserManagementDialog();

  @override
  ConsumerState<_UserManagementDialog> createState() =>
      _UserManagementDialogState();
}

class _UserManagementDialogState extends ConsumerState<_UserManagementDialog> {
  List<PlankaUser>? _users;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final env = await PlankaRepo(ref.read(apiProvider)).users();
      if (!mounted) return;
      setState(() {
        _users = env.items.map(PlankaUser.fromJson).toList();
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Future<void> _mutate(Future<void> Function(PlankaRepo repo) run) async {
    try {
      await run(PlankaRepo(ref.read(apiProvider)));
      await _load();
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selfId = ref.watch(currentUserProvider).value?.id;

    return AlertDialog(
      title: Text(l10n.manageUsersTitle),
      content: SizedBox(
        width: 420,
        height: 480,
        child: _error != null
            ? Center(child: Text('$_error'))
            : _users == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final u in _users!)
                        _UserTile(
                          user: u,
                          isSelf: u.id == selfId,
                          onChangeRole: (role) => _mutate(
                              (repo) => repo.updateUser(u.id, {'role': role})),
                          onToggleDeactivated: () => _mutate((repo) =>
                              repo.updateUser(u.id,
                                  {'isDeactivated': u.isDeactivated != true})),
                          onDelete: () async {
                            final ok = await confirmDialog(context,
                                title: l10n.userDeleteTitle,
                                message: l10n.userDeleteMessage(u.name),
                                confirmLabel: l10n.actionDelete);
                            if (!ok || !context.mounted) return;
                            await _mutate((repo) => repo.deleteUser(u.id));
                          },
                        ),
                      const Divider(),
                      TextButton.icon(
                        icon: const Icon(Icons.person_add_alt),
                        label: Text(l10n.userAdd),
                        onPressed: () => _showAddUserDialog(context),
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

  Future<void> _showAddUserDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    var role = 'boardUser';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.userAdd),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(hintText: l10n.fieldName),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(hintText: l10n.fieldEmail),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(hintText: l10n.fieldPassword),
              ),
              DropdownButton<String>(
                value: role,
                items: [
                  for (final r in _roles)
                    DropdownMenuItem(value: r, child: Text(_roleLabel(l10n, r))),
                ],
                onChanged: (value) => setState(() => role = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.actionAdd),
            ),
          ],
        ),
      ),
    );

    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    if (result != true || email.isEmpty || password.isEmpty || name.isEmpty) {
      return;
    }
    await _mutate((repo) => repo.createUser({
          'email': email,
          'password': password,
          'name': name,
          'role': role,
        }));
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.isSelf,
    required this.onChangeRole,
    required this.onToggleDeactivated,
    required this.onDelete,
  });

  final PlankaUser user;
  final bool isSelf;
  final ValueChanged<String> onChangeRole;
  final VoidCallback onToggleDeactivated;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deactivated = user.isDeactivated == true;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: !deactivated,
      title: Text(user.name,
          style: deactivated
              ? TextStyle(color: Theme.of(context).disabledColor)
              : null),
      subtitle: Text(user.email ?? l10n.valueNotSet),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
              label: Text(user.role == null
                  ? l10n.valueNotSet
                  : _roleLabel(l10n, user.role!))),
          if (!isSelf)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete();
                } else if (value == 'toggleDeactivated') {
                  onToggleDeactivated();
                } else if (_roles.contains(value)) {
                  onChangeRole(value);
                }
              },
              itemBuilder: (context) => [
                for (final r in _roles)
                  if (r != user.role)
                    PopupMenuItem(
                        value: r,
                        child: Text(l10n.userMakeRole(_roleLabel(l10n, r)))),
                PopupMenuItem(
                  value: 'toggleDeactivated',
                  child: Text(
                      deactivated ? l10n.userReactivate : l10n.userDeactivate),
                ),
                PopupMenuItem(value: 'delete', child: Text(l10n.actionDelete)),
              ],
            ),
        ],
      ),
    );
  }
}
