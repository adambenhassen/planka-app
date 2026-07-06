import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/envelope.dart';
import '../api/repositories.dart';
import '../auth/auth_providers.dart';
import '../state/notifications_state.dart';

final projectsProvider = FutureProvider<Envelope>(
    (ref) => PlankaRepo(ref.watch(apiProvider)).projects());

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: Badge.count(
              count: ref.watch(unreadCountProvider),
              isLabelVisible: ref.watch(unreadCountProvider) > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push('/notifications'),
          ),
          const _AccountSwitcher(),
        ],
      ),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(projectsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (env) => RefreshIndicator(
          onRefresh: () => ref.refresh(projectsProvider.future),
          child: _ProjectList(env: env),
        ),
      ),
    );
  }
}

class _ProjectList extends StatelessWidget {
  const _ProjectList({required this.env});
  final Envelope env;

  @override
  Widget build(BuildContext context) {
    final boards = env.included.boards;
    final projects = env.items;
    if (projects.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 120),
        Center(child: Text('No projects yet')),
      ]);
    }
    return ListView(
      children: [
        for (final p in projects) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(p['name'] as String? ?? '',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final b in boards.where((b) => b.projectId == p['id']))
            ListTile(
              leading: const Icon(Icons.view_kanban_outlined),
              title: Text(b.name),
              onTap: () => context.push('/boards/${b.id}'),
            ),
        ],
      ],
    );
  }
}

class _AccountSwitcher extends ConsumerWidget {
  const _AccountSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    final current = ref.watch(currentAccountProvider);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (id) async {
        if (id == '_add') {
          context.push('/login');
          return;
        }
        final account = accounts.where((a) => a.id == id).firstOrNull;
        if (account != null) {
          await ref.read(currentAccountProvider.notifier).select(account);
          ref.invalidate(projectsProvider);
        }
      },
      itemBuilder: (context) => [
        for (final a in accounts)
          PopupMenuItem(
            value: a.id,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(a.id == current?.id
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off),
              title: Text(a.displayName),
              subtitle: Text(a.serverUrl),
            ),
          ),
        const PopupMenuItem(
          value: '_add',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.add),
            title: Text('Add account'),
          ),
        ),
      ],
    );
  }
}
