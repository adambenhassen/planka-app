import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/models.dart';
import '../auth/auth_providers.dart';
import '../state/notifications_state.dart';
import '../state/projects_state.dart';
import '../update/update_service.dart';
import 'widgets/async_retry.dart';
import 'widgets/board_background.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    // Prompt once if a newer APK has been published (Android sideload).
    ref.listen(updateCheckProvider, (_, next) {
      final info = next.value;
      if (info == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update available (v${info.version})'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Get',
            onPressed: () => launchUrl(
              Uri.parse(info.url),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ),
      );
    });
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
      body: asyncRetry(
        projects,
        () => ref.invalidate(projectsProvider),
        (view) => RefreshIndicator(
          onRefresh: () => ref.refresh(projectsProvider.future),
          child: _ProjectList(
            view: view,
            token: ref.watch(currentAccountProvider)?.token,
          ),
        ),
      ),
    );
  }
}

class _ProjectList extends StatelessWidget {
  const _ProjectList({required this.view, required this.token});
  final ProjectsView view;
  final String? token;

  @override
  Widget build(BuildContext context) {
    final boards = view.boards;
    final projects = view.projects;
    if (projects.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No projects yet')),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final p in projects) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Text(
              p.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          GridView.extent(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // Max tile width drives responsive columns: ~2 on a phone, more on
            // a wide desktop window.
            maxCrossAxisExtent: 260,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 16 / 9,
            children: [
              // Boards inherit their project's Planka background (gradient or
              // image); a deterministic color when the project has none.
              for (final b in boards.where((b) => b.projectId == p.id))
                _BoardTile(
                  board: b,
                  background: resolveBoardBackground(
                    p,
                    view.backgroundImages,
                    b.name,
                  ),
                  token: token,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BoardTile extends StatelessWidget {
  const _BoardTile({
    required this.board,
    required this.background,
    required this.token,
  });
  final PlankaBoard board;
  final BoardBackground background;
  final String? token;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          BoardBackgroundView(background: background, token: token),
          // Scrim keeps the white title legible over any tile color or photo.
          ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                board.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: () => context.push('/boards/${board.id}')),
            ),
          ),
        ],
      ),
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
              leading: Icon(
                a.id == current?.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
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
