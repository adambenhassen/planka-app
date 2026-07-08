import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/repositories.dart';
import '../../auth/auth_providers.dart';
import '../../state/current_user_state.dart';
import '../error_handling.dart';
import 'prompt_dialog.dart';

Future<void> showProfileDialog(BuildContext context) => showDialog(
      context: context,
      builder: (_) => const _ProfileDialog(),
    );

class _ProfileDialog extends ConsumerWidget {
  const _ProfileDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    Future<void> mutate(Future<void> Function(PlankaRepo repo) run) async {
      try {
        await run(PlankaRepo(ref.read(apiProvider)));
        ref.invalidate(currentUserProvider);
      } catch (e) {
        if (context.mounted) showApiError(context, e);
      }
    }

    return AlertDialog(
      title: const Text('Profile'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(user.name.isEmpty
                        ? '?'
                        : user.name[0].toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () async {
                      final file = await openFile();
                      if (file == null) return;
                      await mutate((repo) => repo.uploadUserAvatar(user.id,
                          filePath: file.path, name: file.name));
                    },
                    child: const Text('Upload'),
                  ),
                  if (user.avatar != null)
                    TextButton(
                      onPressed: () => mutate((repo) =>
                          repo.updateUser(user.id, {'avatar': null})),
                      child: const Text('Remove'),
                    ),
                ],
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Name'),
                subtitle: Text(user.name),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () async {
                  final value = await promptText(context,
                      title: 'Name', initialValue: user.name);
                  if (value == null) return;
                  await mutate(
                      (repo) => repo.updateUser(user.id, {'name': value}));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Phone'),
                subtitle: Text(user.phone ?? '—'),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () async {
                  final value = await promptText(context,
                      title: 'Phone', initialValue: user.phone);
                  if (value == null) return;
                  await mutate(
                      (repo) => repo.updateUser(user.id, {'phone': value}));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Organization'),
                subtitle: Text(user.organization ?? '—'),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () async {
                  final value = await promptText(context,
                      title: 'Organization', initialValue: user.organization);
                  if (value == null) return;
                  await mutate((repo) =>
                      repo.updateUser(user.id, {'organization': value}));
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Email'),
                subtitle: Text(user.email ?? '—'),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () => _showCredentialDialog(
                  context,
                  title: 'Change email',
                  valueLabel: 'New email',
                  onSubmit: (value, currentPassword) => mutate((repo) =>
                      repo.updateUserEmail(user.id,
                          email: value, currentPassword: currentPassword)),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Username'),
                subtitle: Text(user.username ?? '—'),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () => _showCredentialDialog(
                  context,
                  title: 'Change username',
                  valueLabel: 'New username',
                  onSubmit: (value, currentPassword) => mutate((repo) =>
                      repo.updateUserUsername(user.id,
                          username: value, currentPassword: currentPassword)),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Password'),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () => _showCredentialDialog(
                  context,
                  title: 'Change password',
                  valueLabel: 'New password',
                  obscureValue: true,
                  onSubmit: (value, currentPassword) async {
                    try {
                      final repo = PlankaRepo(ref.read(apiProvider));
                      final env = await repo.updateUserPassword(user.id,
                          password: value, currentPassword: currentPassword);
                      // A password change on the caller's own account invalidates the
                      // old token; the server returns a fresh one in the response's
                      // `included.accessToken`. If it's absent (e.g. server changed
                      // shape), the next request 401s and the existing onUnauthorized
                      // flow forces re-login — no separate handling needed here.
                      final newToken = env.accessToken;
                      final account = ref.read(currentAccountProvider);
                      if (newToken != null && account != null) {
                        await ref
                            .read(currentAccountProvider.notifier)
                            .select(account.copyWith(token: newToken));
                      }
                      ref.invalidate(currentUserProvider);
                    } catch (e) {
                      if (context.mounted) showApiError(context, e);
                    }
                  },
                ),
              ),
            ],
          ),
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

/// Prompts for a new value plus the current password (required to change
/// email/username/password for one's own account), then calls [onSubmit].
Future<void> _showCredentialDialog(
  BuildContext context, {
  required String title,
  required String valueLabel,
  required Future<void> Function(String value, String currentPassword)
      onSubmit,
  bool obscureValue = false,
}) async {
  final valueController = TextEditingController();
  final passwordController = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: valueController,
            autofocus: true,
            obscureText: obscureValue,
            decoration: InputDecoration(hintText: valueLabel),
          ),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Current password'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  final value = valueController.text.trim();
  final password = passwordController.text;
  valueController.dispose();
  passwordController.dispose();
  if (result != true || value.isEmpty || password.isEmpty) return;
  await onSubmit(value, password);
}
