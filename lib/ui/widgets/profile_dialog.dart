import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/repositories.dart';
import '../../auth/auth_providers.dart';
import '../../l10n/gen/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
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
      title: Text(l10n.profileTitle),
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
                    child: Text(l10n.actionUpload),
                  ),
                  if (user.avatar != null)
                    TextButton(
                      onPressed: () => mutate((repo) =>
                          repo.updateUser(user.id, {'avatar': null})),
                      child: Text(l10n.actionRemove),
                    ),
                ],
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.fieldName),
                subtitle: Text(user.name),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () async {
                  final value = await promptText(context,
                      title: l10n.fieldName, initialValue: user.name);
                  if (value == null) return;
                  await mutate(
                      (repo) => repo.updateUser(user.id, {'name': value}));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.profilePhone),
                subtitle: Text(user.phone ?? l10n.valueNotSet),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () async {
                  final value = await promptText(context,
                      title: l10n.profilePhone, initialValue: user.phone);
                  if (value == null) return;
                  await mutate(
                      (repo) => repo.updateUser(user.id, {'phone': value}));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.profileOrganization),
                subtitle: Text(user.organization ?? l10n.valueNotSet),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () async {
                  final value = await promptText(context,
                      title: l10n.profileOrganization,
                      initialValue: user.organization);
                  if (value == null) return;
                  await mutate((repo) =>
                      repo.updateUser(user.id, {'organization': value}));
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.fieldEmail),
                subtitle: Text(user.email ?? l10n.valueNotSet),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () => _showCredentialDialog(
                  context,
                  title: l10n.profileChangeEmail,
                  valueLabel: l10n.profileNewEmail,
                  onSubmit: (value, currentPassword) => mutate((repo) =>
                      repo.updateUserEmail(user.id,
                          email: value, currentPassword: currentPassword)),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.profileUsername),
                subtitle: Text(user.username ?? l10n.valueNotSet),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () => _showCredentialDialog(
                  context,
                  title: l10n.profileChangeUsername,
                  valueLabel: l10n.profileNewUsername,
                  onSubmit: (value, currentPassword) => mutate((repo) =>
                      repo.updateUserUsername(user.id,
                          username: value, currentPassword: currentPassword)),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.fieldPassword),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () => _showCredentialDialog(
                  context,
                  title: l10n.profileChangePassword,
                  valueLabel: l10n.profileNewPassword,
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
          child: Text(l10n.actionClose),
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
            decoration: InputDecoration(
                hintText: AppLocalizations.of(ctx).profileCurrentPassword),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(AppLocalizations.of(ctx).actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(AppLocalizations.of(ctx).actionSave),
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
