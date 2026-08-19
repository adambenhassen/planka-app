import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../auth/auth_providers.dart';
import '../l10n/gen/app_localizations.dart';
import '../state/board_state.dart';
import 'error_handling.dart';
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

class CustomFieldsManagerSheet extends ConsumerWidget {
  const CustomFieldsManagerSheet({
    super.key,
    required this.boardId,
    this.cardId,
    this.scrollController,
  });

  final String boardId;
  final String? cardId;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final boardAsync = ref.watch(boardProvider(boardId));
    final state = boardAsync.value;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final notifier = ref.read(boardProvider(boardId).notifier);
    final currentUserId = ref.watch(currentAccountProvider)?.userId ?? '';

    // True only when the app positively knows the user is a viewer — hide write
    // affordances in that case and let the server gate everything else.
    final isViewer = state.boardMemberships.any(
        (m) => m.userId == currentUserId && m.role == 'viewer');

    return _ManagerBody(
      boardId: boardId,
      cardId: cardId,
      state: state,
      notifier: notifier,
      scrollController: scrollController,
      isViewer: isViewer,
      l10n: l10n,
    );
  }
}

class _ManagerBody extends StatelessWidget {
  const _ManagerBody({
    required this.boardId,
    required this.cardId,
    required this.state,
    required this.notifier,
    required this.scrollController,
    required this.isViewer,
    required this.l10n,
  });

  final String boardId;
  final String? cardId;
  final BoardState state;
  final BoardNotifier notifier;
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
    final boardName = state.board.name;
    final hasCard = cardId != null;

    return Column(
      children: [
        // Header
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
                  const SizedBox(width: 48),
                  Expanded(
                    child: Column(
                      children: [
                        Text(l10n.customFieldsTitle,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(boardName,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
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
        // Body
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
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
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
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
              onSubmit: (name) => guardMutation(
                context,
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
    guardMutation(context, notifier.renameCustomFieldGroup(group.id, name));
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
    guardMutation(context, notifier.deleteCustomFieldGroup(group.id));
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
                        guardMutation(context,
                            notifier.moveCustomFieldGroupUp(group.id));
                        SemanticsService.sendAnnouncement(
                            View.of(context),
                            l10n.customFieldsMovedToPosition(
                                _displayName,
                                groupIndex,
                                groupCount),
                            TextDirection.ltr);
                      case 'down':
                        guardMutation(context,
                            notifier.moveCustomFieldGroupDown(group.id));
                        SemanticsService.sendAnnouncement(
                            View.of(context),
                            l10n.customFieldsMovedToPosition(
                                _displayName,
                                groupIndex + 2,
                                groupCount),
                            TextDirection.ltr);
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
        if (_isInstantiated)
          // Read-only: fields belong to the base group
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              l10n.customFieldsTemplateFieldsReadOnly,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          )
        else ...[
          for (int fi = 0; fi < fields.length; fi++)
            _FieldRow(
              field: fields[fi],
              fieldIndex: fi,
              fieldCount: fields.length,
              notifier: notifier,
              isViewer: isViewer,
              isCard: isCard,
              groupName: _displayName,
              l10n: l10n,
            ),
          if (!isViewer)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: InlineAddField(
                label: l10n.customFieldsAddField,
                maxLength: _kNameMaxLength,
                onSubmit: (name) => guardMutation(
                    context, notifier.createCustomField(group.id, name)),
              ),
            ),
        ],
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.fieldIndex,
    required this.fieldCount,
    required this.notifier,
    required this.isViewer,
    required this.isCard,
    required this.groupName,
    required this.l10n,
  });

  final PlankaCustomField field;
  final int fieldIndex;
  final int fieldCount;
  final BoardNotifier notifier;
  final bool isViewer;
  final bool isCard;
  final String groupName;
  final AppLocalizations l10n;

  Future<void> _rename(BuildContext context) async {
    final name = await promptText(
      context,
      title: l10n.customFieldsRenameFieldTitle,
      initialValue: field.name,
    );
    if (name == null || !context.mounted) return;
    guardMutation(context, notifier.renameCustomField(field.id, name));
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
    guardMutation(context, notifier.deleteCustomField(field.id));
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
      trailing: isViewer
          ? null
          : PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              tooltip: '${l10n.customFieldsMoreActions} ${field.name}',
              onSelected: (action) async {
                switch (action) {
                  case 'rename':
                    await _rename(context);
                  case 'front':
                    guardMutation(
                      context,
                      notifier.toggleCustomFieldFrontOfCard(
                          field.id, !showOnFront),
                    );
                  case 'up':
                    guardMutation(
                        context, notifier.moveCustomFieldUp(field.id));
                    SemanticsService.sendAnnouncement(
                        View.of(context),
                        l10n.customFieldsMovedToPosition(
                            field.name, fieldIndex, fieldCount),
                        TextDirection.ltr);
                  case 'down':
                    guardMutation(
                        context, notifier.moveCustomFieldDown(field.id));
                    SemanticsService.sendAnnouncement(
                        View.of(context),
                        l10n.customFieldsMovedToPosition(
                            field.name, fieldIndex + 2, fieldCount),
                        TextDirection.ltr);
                  case 'delete':
                    await _delete(context);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'rename',
                    child: Text(l10n.customFieldsMenuRename)),
                CheckedPopupMenuItem(
                    value: 'front',
                    checked: showOnFront,
                    child:
                        Text(l10n.customFieldsMenuShowOnFrontOfCard)),
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
