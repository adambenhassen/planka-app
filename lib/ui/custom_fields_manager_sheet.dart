import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../api/planka_api.dart';
import '../auth/auth_providers.dart';
import '../l10n/gen/app_localizations.dart';
import '../state/board_state.dart';
import '../state/projects_state.dart';
import 'error_handling.dart';
import 'widgets/async_retry.dart';
import 'widgets/confirm_dialog.dart';
import 'widgets/inline_add_field.dart';
import 'widgets/prompt_dialog.dart';

const int _kNameMaxLength = 128;

Future<void> showCustomFieldsManagerSheet(
  BuildContext context, {
  required String boardId,
  String? cardId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 1,
      builder: (ctx, sc) => CustomFieldsManagerSheet(
        boardId: boardId,
        cardId: cardId,
        scrollController: sc,
      ),
    ),
  );
}

/// Opens the manager straight on the templates page, with no back affordance:
/// entered from the projects screen there is no fields page behind it.
Future<void> showProjectTemplatesSheet(
  BuildContext context, {
  required String projectId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 1,
      builder: (ctx, sc) => CustomFieldsManagerSheet(
        projectId: projectId,
        scrollController: sc,
      ),
    ),
  );
}

/// Whether a template write names a record the projects view still holds. A
/// 404 on such a write is the server's non-manager refusal (`projectNotFound`).
/// Against an id another client has already deleted it is a plain missing
/// record, and telling the user they are not a manager would hide the real
/// cause — such writes fall through to [showApiError] instead.
bool templateRecordInView(
  ProjectsView? view, {
  String? projectId,
  String? templateId,
  String? fieldId,
}) {
  if (view == null) return false;
  if (projectId != null) {
    return view.projects.any((p) => p.id == projectId);
  }
  if (templateId != null) {
    return view.baseCustomFieldGroups.any((b) => b.id == templateId);
  }
  if (fieldId != null) return view.customFields.any((f) => f.id == fieldId);
  return false;
}

/// Surfaces [e] to the user. A board-level write refused with 403 maps to the
/// board-editor-only copy. When [expectManagerRefusal] holds — the write names
/// a template record still present in the projects view — a 404 maps to the
/// manager-only copy, since the server answers a non-manager with
/// `projectNotFound`, which would read as a missing project. Anything else
/// goes through [showApiError].
void _handleCfError(BuildContext context, AppLocalizations l10n, Object e,
    {bool expectManagerRefusal = false}) {
  if (!context.mounted) {
    debugPrint('_handleCfError: failed after context unmounted: $e');
    return;
  }
  final code = e is ApiException ? e.statusCode : null;
  final String? message;
  if (expectManagerRefusal && code == 404) {
    message = l10n.customFieldsManagersRequired;
  } else if (!expectManagerRefusal && code == 403) {
    message = l10n.customFieldsEditorRequired;
  } else {
    message = null;
  }
  if (message != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  } else {
    showApiError(context, e);
  }
}

/// Like [guardMutation] but routes errors through [_handleCfError].
void _guardCfMutation(
  BuildContext context,
  AppLocalizations l10n,
  Future<void> future, {
  bool expectManagerRefusal = false,
}) {
  future.catchError((Object e) {
    if (context.mounted) {
      _handleCfError(context, l10n, e, expectManagerRefusal: expectManagerRefusal);
    } else {
      // The sheet is gone so the snackbar can't be shown, but the failure
      // still happened. Log rather than swallow it silently.
      debugPrint(
          '_guardCfMutation: mutation failed after context unmounted: $e');
    }
  });
}

/// What a field row can do. Both pages render [_FieldRow]; the board page
/// backs it with [BoardNotifier], the templates page with [ProjectsNotifier].
class _FieldActions {
  const _FieldActions({
    required this.onRename,
    required this.onToggleFront,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  final Future<void> Function(PlankaCustomField field, String name) onRename;
  final Future<void> Function(PlankaCustomField field, bool show) onToggleFront;
  final Future<void> Function(PlankaCustomField field) onMoveUp;
  final Future<void> Function(PlankaCustomField field) onMoveDown;
  final Future<void> Function(PlankaCustomField field) onDelete;
}

class CustomFieldsManagerSheet extends ConsumerStatefulWidget {
  const CustomFieldsManagerSheet({
    super.key,
    this.boardId,
    this.cardId,
    this.projectId,
    this.scrollController,
  })  : assert(boardId != null || projectId != null),
        assert(projectId == null || cardId == null);

  /// Set when opened from a board (or card); page 2 is then reachable through
  /// the templates section's Manage templates button.
  final String? boardId;

  /// Set when opened from a card, giving the sheet its "This card" section.
  final String? cardId;

  /// Set alone when opened from the projects screen: the sheet starts and
  /// stays on the templates page, which is scoped to the project.
  final String? projectId;

  final ScrollController? scrollController;

  @override
  ConsumerState<CustomFieldsManagerSheet> createState() =>
      _CustomFieldsManagerSheetState();
}

class _CustomFieldsManagerSheetState
    extends ConsumerState<CustomFieldsManagerSheet> {
  bool _onTemplates = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final projectsAsync = ref.watch(projectsProvider);
    final boardAsync = widget.boardId == null
        ? null
        : ref.watch(boardProvider(widget.boardId!));
    final currentUserId = ref.watch(currentAccountProvider)?.userId ?? '';

    // The project id the templates are scoped to: given directly from the
    // projects screen, otherwise the open board's.
    final projectId =
        widget.projectId ?? boardAsync?.value?.board.projectId ?? '';
    final projectName = projectsAsync.value?.projects
            .where((p) => p.id == projectId)
            .firstOrNull
            ?.name ??
        '';
    final onTemplates = widget.boardId == null || _onTemplates;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: onTemplates && widget.boardId != null
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: l10n.customFieldsBackToFields,
                            onPressed: () =>
                                setState(() => _onTemplates = false),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(l10n.customFieldsTitle,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          onTemplates
                              ? projectName
                              : (boardAsync?.value?.board.name ?? ''),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.actionClose,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: onTemplates
              ? _TemplatesBody(
                  projectId: projectId,
                  scrollController: widget.scrollController,
                  l10n: l10n,
                )
              : asyncRetry(
                  boardAsync!,
                  () => ref.invalidate(boardProvider(widget.boardId!)),
                  (state) {
                    final notifier =
                        ref.read(boardProvider(widget.boardId!).notifier);
                    final isViewer = state.boardMemberships.any(
                        (m) => m.userId == currentUserId && m.role == 'viewer');
                    return _ManagerBody(
                      boardId: widget.boardId!,
                      cardId: widget.cardId,
                      state: state,
                      notifier: notifier,
                      projectsView: projectsAsync.value,
                      projectsLoading:
                          projectsAsync.isLoading && !projectsAsync.hasValue,
                      projectsFailed: projectsAsync.hasError,
                      onRetryProjects: () => ref.invalidate(projectsProvider),
                      onManageTemplates: () =>
                          setState(() => _onTemplates = true),
                      scrollController: widget.scrollController,
                      isViewer: isViewer,
                      l10n: l10n,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ManagerBody extends StatelessWidget {
  const _ManagerBody({
    required this.boardId,
    required this.cardId,
    required this.state,
    required this.notifier,
    required this.projectsView,
    required this.projectsLoading,
    required this.projectsFailed,
    required this.onRetryProjects,
    required this.onManageTemplates,
    required this.scrollController,
    required this.isViewer,
    required this.l10n,
  });

  final String boardId;
  final String? cardId;
  final BoardState state;
  final BoardNotifier notifier;

  /// Null while the projects payload is loading or has failed; the templates
  /// section renders accordingly without blocking the rest of the sheet.
  final ProjectsView? projectsView;
  final bool projectsLoading;
  final bool projectsFailed;
  final VoidCallback onRetryProjects;
  final VoidCallback onManageTemplates;
  final ScrollController? scrollController;
  final bool isViewer;
  final AppLocalizations l10n;

  Widget _section(BuildContext context, String title, Widget child) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(title,
                  style: Theme.of(context).textTheme.labelLarge),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final hasCard = cardId != null;
    final projectId = state.board.projectId;

    return LayoutBuilder(builder: (context, constraints) {
      final bodyWidth =
          constraints.maxWidth > 640 ? 640.0 : constraints.maxWidth;
      return Center(
        child: SizedBox(
          width: bodyWidth,
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                32 + MediaQuery.viewInsetsOf(context).bottom),
            children: [
              if (isViewer)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.customFieldsViewerReadOnly,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                  ),
                ),
              if (hasCard)
                _section(
                  context,
                  l10n.customFieldsCardSection,
                  _GroupList(
                    groups: state.customFieldGroups
                        .where((g) => g.cardId == cardId)
                        .toList()
                      ..sort((a, b) =>
                          (a.position ?? 0).compareTo(b.position ?? 0)),
                    state: state,
                    notifier: notifier,
                    isViewer: isViewer,
                    isCard: true,
                    cardId: cardId!,
                    emptyText: l10n.customFieldsCardEmpty,
                    l10n: l10n,
                  ),
                ),
              _section(
                context,
                l10n.customFieldsBoardSection,
                _GroupList(
                  groups: state.customFieldGroups
                      .where((g) => g.boardId == boardId)
                      .toList()
                    ..sort((a, b) =>
                        (a.position ?? 0).compareTo(b.position ?? 0)),
                  state: state,
                  notifier: notifier,
                  isViewer: isViewer,
                  isCard: false,
                  cardId: null,
                  emptyText: l10n.customFieldsBoardEmpty,
                  l10n: l10n,
                ),
              ),
              _section(
                context,
                l10n.customFieldsTemplatesSection,
                _TemplateSection(
                  boardId: boardId,
                  projectId: projectId,
                  state: state,
                  notifier: notifier,
                  projectsView: projectsView,
                  loading: projectsLoading,
                  failed: projectsFailed,
                  onRetry: onRetryProjects,
                  onManageTemplates: onManageTemplates,
                  isViewer: isViewer,
                  l10n: l10n,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _GroupList extends StatelessWidget {
  const _GroupList({
    required this.groups,
    required this.state,
    required this.notifier,
    required this.isViewer,
    required this.isCard,
    required this.cardId,
    required this.emptyText,
    required this.l10n,
  });

  final List<PlankaCustomFieldGroup> groups;
  final BoardState state;
  final BoardNotifier notifier;
  final bool isViewer;
  final bool isCard;
  final String? cardId;
  final String emptyText;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (groups.isEmpty)
          Text(emptyText,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant)),
        for (int gi = 0; gi < groups.length; gi++) ...[
          _GroupRow(
            group: groups[gi],
            groupIndex: gi,
            groupCount: groups.length,
            state: state,
            notifier: notifier,
            isViewer: isViewer,
            isCard: isCard,
            l10n: l10n,
          ),
        ],
        if (!isViewer)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InlineAddField(
              label: l10n.customFieldsAddGroup,
              maxLength: _kNameMaxLength,
              onSubmit: (name) => _guardCfMutation(
                context,
                l10n,
                isCard
                    ? notifier.createCardCustomFieldGroup(cardId!, name)
                    : notifier.createBoardCustomFieldGroup(name),
              ),
            ),
          ),
      ],
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.groupIndex,
    required this.groupCount,
    required this.state,
    required this.notifier,
    required this.isViewer,
    required this.isCard,
    required this.l10n,
  });

  final PlankaCustomFieldGroup group;
  final int groupIndex;
  final int groupCount;
  final BoardState state;
  final BoardNotifier notifier;
  final bool isViewer;
  final bool isCard;
  final AppLocalizations l10n;

  bool get _isInstantiated => group.baseCustomFieldGroupId != null;

  String get _displayName => state.customFieldGroupName(group);

  List<PlankaCustomField> get _fields => state.customFieldsOf(group);

  Future<void> _rename(BuildContext context) async {
    final name = await promptText(
      context,
      title: l10n.customFieldsRenameGroupTitle,
      initialValue: group.name,
    );
    if (name == null || !context.mounted) return;
    _guardCfMutation(
        context, l10n, notifier.renameCustomFieldGroup(group.id, name));
  }

  Future<void> _delete(BuildContext context) async {
    final fieldCount = _fields.length;
    final confirmed = await confirmDialog(
      context,
      destructive: true,
      title: _isInstantiated
          ? l10n.customFieldsInstantiatedGroupRemoveTitle
          : (isCard
              ? l10n.customFieldsCardGroupDeleteTitle
              : l10n.customFieldsGroupDeleteTitle),
      message: _isInstantiated
          ? l10n.customFieldsInstantiatedGroupRemoveMessage(_displayName)
          : (isCard
              ? l10n.customFieldsCardGroupDeleteMessage(
                  _displayName, fieldCount)
              : l10n.customFieldsGroupDeleteMessage(_displayName, fieldCount)),
      confirmLabel: _isInstantiated
          ? l10n.customFieldsMenuRemoveFromBoard
          : l10n.actionDelete,
    );
    if (!confirmed || !context.mounted) return;
    _guardCfMutation(
        context, l10n, notifier.deleteCustomFieldGroup(group.id));
  }

  @override
  Widget build(BuildContext context) {
    final fields = _fields;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _displayName,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: _isInstantiated
              ? Text(
                  l10n.customFieldsFromTemplate,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant),
                )
              : null,
          trailing: isViewer
              ? null
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  tooltip:
                      '${l10n.customFieldsMoreActions} $_displayName',
                  onSelected: (action) async {
                    switch (action) {
                      case 'rename':
                        await _rename(context);
                      case 'up':
                        try {
                          await notifier.moveCustomFieldGroupUp(group.id);
                        } catch (e) {
                          if (context.mounted) _handleCfError(context, l10n, e);
                          return;
                        }
                        if (context.mounted) {
                          SemanticsService.sendAnnouncement(
                              View.of(context),
                              l10n.customFieldsMovedToPosition(
                                  _displayName,
                                  groupIndex,
                                  groupCount),
                              TextDirection.ltr);
                        }
                      case 'down':
                        try {
                          await notifier.moveCustomFieldGroupDown(group.id);
                        } catch (e) {
                          if (context.mounted) _handleCfError(context, l10n, e);
                          return;
                        }
                        if (context.mounted) {
                          SemanticsService.sendAnnouncement(
                              View.of(context),
                              l10n.customFieldsMovedToPosition(
                                  _displayName,
                                  groupIndex + 2,
                                  groupCount),
                              TextDirection.ltr);
                        }
                      case 'delete':
                        await _delete(context);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'rename',
                        child: Text(l10n.customFieldsMenuRename)),
                    PopupMenuItem(
                        enabled: groupIndex > 0,
                        value: 'up',
                        child: Text(l10n.customFieldsMenuMoveUp)),
                    PopupMenuItem(
                        enabled: groupIndex < groupCount - 1,
                        value: 'down',
                        child: Text(l10n.customFieldsMenuMoveDown)),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text(_isInstantiated
                            ? l10n.customFieldsMenuRemoveFromBoard
                            : l10n.customFieldsMenuDelete)),
                  ],
                ),
        ),
        if (_isInstantiated) ...[
          // Template fields are displayed read-only; no edit menu or add row.
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              l10n.customFieldsTemplateFieldsReadOnly,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          for (int fi = 0; fi < fields.length; fi++)
            _FieldRow(
              field: fields[fi],
              fieldIndex: fi,
              fieldCount: fields.length,
              actions: _FieldActions(
                onRename: (_, _) async {},
                onToggleFront: (_, _) async {},
                onMoveUp: (_) async {},
                onMoveDown: (_) async {},
                onDelete: (_) async {},
              ),
              isCard: isCard,
              readOnly: true,
              l10n: l10n,
            ),
        ] else ...[
          for (int fi = 0; fi < fields.length; fi++)
            _FieldRow(
              field: fields[fi],
              fieldIndex: fi,
              fieldCount: fields.length,
              actions: _FieldActions(
                onRename: (field, name) =>
                    notifier.renameCustomField(field.id, name),
                onToggleFront: (field, show) =>
                    notifier.toggleCustomFieldFrontOfCard(field.id, show),
                onMoveUp: (field) => notifier.moveCustomFieldUp(field.id),
                onMoveDown: (field) => notifier.moveCustomFieldDown(field.id),
                onDelete: (field) => notifier.deleteCustomField(field.id),
              ),
              isCard: isCard,
              l10n: l10n,
            ),
          if (!isViewer)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: InlineAddField(
                label: l10n.customFieldsAddField,
                maxLength: _kNameMaxLength,
                onSubmit: (name) => _guardCfMutation(
                    context, l10n, notifier.createCustomField(group.id, name)),
              ),
            ),
        ],
      ],
    );
  }
}

/// One ListTile per project template on page 1's templates section, with
/// Add to board / Added as its trailing.
class _TemplateSection extends StatelessWidget {
  const _TemplateSection({
    required this.boardId,
    required this.projectId,
    required this.state,
    required this.notifier,
    required this.projectsView,
    required this.loading,
    required this.failed,
    required this.onRetry,
    required this.onManageTemplates,
    required this.isViewer,
    required this.l10n,
  });

  final String boardId;
  final String projectId;
  final BoardState state;
  final BoardNotifier notifier;

  /// Null while the projects payload is loading or has failed.
  final ProjectsView? projectsView;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;
  final VoidCallback onManageTemplates;
  final bool isViewer;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // The projects fetch feeding this section alone; the rest of the sheet
    // stays interactive while it is in flight or broken.
    if (loading && projectsView == null) {
      return const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (failed && projectsView == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.customFieldsTemplatesLoadFailed,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          TextButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
        ],
      );
    }
    final view = projectsView!;
    final templates = view.baseGroupsOf(projectId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (templates.isEmpty)
          Text(l10n.customFieldsTemplatesEmpty,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
        for (final template in templates)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.layers_outlined),
            title: Text(
              template.name ?? '',
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              l10n.customFieldsFieldCount(
                  view.fieldsOfBaseGroup(template.id).length),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            trailing: state.customFieldGroups.any((g) =>
                    g.boardId == boardId &&
                    g.baseCustomFieldGroupId == template.id)
                ? Text(
                    l10n.customFieldsAddedToBoard,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                  )
                : (isViewer
                    ? null
                    : TextButton(
                        onPressed: () => _guardCfMutation(
                            context,
                            l10n,
                            notifier
                                .instantiateTemplateOnBoard(template.id)),
                        child: Text(l10n.customFieldsAddToBoard),
                      )),
          ),
        TextButton(
          onPressed: onManageTemplates,
          child: Text(l10n.customFieldsManageTemplates),
        ),
      ],
    );
  }
}

/// Page 2: the project's templates with full create/rename/delete and their
/// fields. Templates carry no server position, so there is deliberately no
/// reorder control here — the menu simply has no move items to disable.
class _TemplatesBody extends ConsumerWidget {
  const _TemplatesBody({
    required this.projectId,
    required this.scrollController,
    required this.l10n,
  });

  final String projectId;
  final ScrollController? scrollController;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    return asyncRetry(
      projectsAsync,
      () => ref.invalidate(projectsProvider),
      (view) {
        final notifier = ref.read(projectsProvider.notifier);
        final templates = view.baseGroupsOf(projectId);
        return LayoutBuilder(builder: (context, constraints) {
          final bodyWidth =
              constraints.maxWidth > 640 ? 640.0 : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: bodyWidth,
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(16, 8, 16,
                    32 + MediaQuery.viewInsetsOf(context).bottom),
                children: [
                  if (templates.isEmpty)
                    Text(l10n.customFieldsTemplatesEmpty,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                  for (final template in templates)
                    _TemplateBlock(
                      template: template,
                      fields: view.fieldsOfBaseGroup(template.id),
                      notifier: notifier,
                      l10n: l10n,
                    ),
                  InlineAddField(
                    label: l10n.customFieldsAddTemplate,
                    maxLength: _kNameMaxLength,
                    onSubmit: (name) => _guardCfMutation(
                        context,
                        l10n,
                        notifier.createTemplate(projectId, name),
                        expectManagerRefusal:
                            templateRecordInView(view, projectId: projectId)),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

class _TemplateBlock extends ConsumerWidget {
  const _TemplateBlock({
    required this.template,
    required this.fields,
    required this.notifier,
    required this.l10n,
  });

  final PlankaBaseCustomFieldGroup template;
  final List<PlankaCustomField> fields;
  final ProjectsNotifier notifier;
  final AppLocalizations l10n;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await promptText(
      context,
      title: l10n.customFieldsRenameGroupTitle,
      initialValue: template.name,
    );
    if (name == null || !context.mounted) return;
    _guardCfMutation(context, l10n, notifier.renameTemplate(template.id, name),
        expectManagerRefusal:
            templateRecordInView(ref.read(projectsProvider).value,
                templateId: template.id));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDialog(
      context,
      destructive: true,
      title: l10n.customFieldsTemplateDeleteTitle,
      message: l10n.customFieldsTemplateDeleteMessage(
          template.name ?? '', fields.length),
      confirmLabel: l10n.actionDelete,
    );
    if (!confirmed || !context.mounted) return;
    _guardCfMutation(context, l10n, notifier.deleteTemplate(template.id),
        expectManagerRefusal:
            templateRecordInView(ref.read(projectsProvider).value,
                templateId: template.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool refusalExpected({String? fieldId}) => templateRecordInView(
        ref.read(projectsProvider).value,
        templateId: template.id,
        fieldId: fieldId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            template.name ?? '',
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            l10n.customFieldsFieldCount(fields.length),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            tooltip: '${l10n.customFieldsMoreActions} ${template.name ?? ''}',
            onSelected: (action) async {
              switch (action) {
                case 'rename':
                  await _rename(context, ref);
                case 'delete':
                  await _delete(context, ref);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'rename', child: Text(l10n.customFieldsMenuRename)),
              PopupMenuItem(
                  value: 'delete', child: Text(l10n.customFieldsMenuDelete)),
            ],
          ),
        ),
        for (int fi = 0; fi < fields.length; fi++)
          _FieldRow(
            field: fields[fi],
            fieldIndex: fi,
            fieldCount: fields.length,
            actions: _FieldActions(
              onRename: (field, name) =>
                  notifier.renameTemplateField(field.id, name),
              onToggleFront: (field, show) =>
                  notifier.toggleTemplateFieldFrontOfCard(field.id, show),
              onMoveUp: (field) => notifier.moveTemplateFieldUp(field.id),
              onMoveDown: (field) => notifier.moveTemplateFieldDown(field.id),
              onDelete: (field) => notifier.deleteTemplateField(field.id),
            ),
            isCard: false,
            expectManagerRefusal: (field) => refusalExpected(fieldId: field.id),
            l10n: l10n,
          ),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 4),
          child: InlineAddField(
            label: l10n.customFieldsAddField,
            maxLength: _kNameMaxLength,
            onSubmit: (name) => _guardCfMutation(
                context,
                l10n,
                notifier.createTemplateField(template.id, name),
                expectManagerRefusal: refusalExpected()),
          ),
        ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.fieldIndex,
    required this.fieldCount,
    required this.actions,
    required this.isCard,
    required this.l10n,
    this.readOnly = false,
    this.expectManagerRefusal,
  });

  final PlankaCustomField field;
  final int fieldIndex;
  final int fieldCount;
  final _FieldActions actions;

  /// Only changes the delete confirmation's copy: a field of a card-level
  /// group takes that card's values with it, not the whole board's.
  final bool isCard;

  /// True for an instantiated group's template fields: no menu is rendered.
  final bool readOnly;

  /// Decides per write whether a 404 should read as the manager-only refusal:
  /// true only while the projects view still holds this very field. Null on
  /// board and card pages, where a 404 is never that refusal.
  final bool Function(PlankaCustomField field)? expectManagerRefusal;
  final AppLocalizations l10n;

  Future<void> _rename(BuildContext context) async {
    final name = await promptText(
      context,
      title: l10n.customFieldsRenameFieldTitle,
      initialValue: field.name,
    );
    if (name == null || !context.mounted) return;
    _guardCfMutation(context, l10n, actions.onRename(field, name),
        expectManagerRefusal: expectManagerRefusal?.call(field) ?? false);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await confirmDialog(
      context,
      destructive: true,
      title: isCard
          ? l10n.customFieldsFieldInCardGroupDeleteTitle
          : l10n.customFieldsFieldInGroupDeleteTitle,
      message: isCard
          ? l10n.customFieldsFieldInCardGroupDeleteMessage(field.name)
          : l10n.customFieldsFieldInGroupDeleteMessage(field.name),
      confirmLabel: l10n.actionDelete,
    );
    if (!confirmed || !context.mounted) return;
    _guardCfMutation(context, l10n, actions.onDelete(field),
        expectManagerRefusal: expectManagerRefusal?.call(field) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final showOnFront = field.showOnFrontOfCard == true;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 16),
      title: Text(
        field.name,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: showOnFront
          ? Text(
              l10n.customFieldsMenuShowOnFrontOfCard,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            )
          : null,
      trailing: readOnly
          ? null
          : PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        tooltip: '${l10n.customFieldsMoreActions} ${field.name}',
        onSelected: (action) async {
          switch (action) {
            case 'rename':
              await _rename(context);
            case 'front':
              _guardCfMutation(
                context,
                l10n,
                actions.onToggleFront(field, !showOnFront),
                expectManagerRefusal:
                    expectManagerRefusal?.call(field) ?? false,
              );
            case 'up':
              try {
                await actions.onMoveUp(field);
              } catch (e) {
                if (context.mounted) _handleCfError(context, l10n, e);
                return;
              }
              if (context.mounted) {
                SemanticsService.sendAnnouncement(
                    View.of(context),
                    l10n.customFieldsMovedToPosition(
                        field.name, fieldIndex, fieldCount),
                    TextDirection.ltr);
              }
            case 'down':
              try {
                await actions.onMoveDown(field);
              } catch (e) {
                if (context.mounted) _handleCfError(context, l10n, e);
                return;
              }
              if (context.mounted) {
                SemanticsService.sendAnnouncement(
                    View.of(context),
                    l10n.customFieldsMovedToPosition(
                        field.name, fieldIndex + 2, fieldCount),
                    TextDirection.ltr);
              }
            case 'delete':
              await _delete(context);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'rename', child: Text(l10n.customFieldsMenuRename)),
          CheckedPopupMenuItem(
              value: 'front',
              checked: showOnFront,
              child: Text(l10n.customFieldsMenuShowOnFrontOfCard)),
          PopupMenuItem(
              enabled: fieldIndex > 0,
              value: 'up',
              child: Text(l10n.customFieldsMenuMoveUp)),
          PopupMenuItem(
              enabled: fieldIndex < fieldCount - 1,
              value: 'down',
              child: Text(l10n.customFieldsMenuMoveDown)),
          PopupMenuItem(
              value: 'delete',
              child: Text(l10n.customFieldsMenuDelete)),
        ],
      ),
    );
  }
}
