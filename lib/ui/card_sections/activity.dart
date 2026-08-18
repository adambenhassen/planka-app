import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/board_state.dart';

IconData _iconFor(PlankaActionType type) => switch (type) {
      PlankaActionType.createCard => Icons.add_circle_outline,
      PlankaActionType.moveCard => Icons.swap_horiz,
      PlankaActionType.addMemberToCard => Icons.person_add_alt,
      PlankaActionType.removeMemberFromCard => Icons.person_remove_outlined,
      PlankaActionType.completeTask => Icons.check_circle_outline,
      PlankaActionType.uncompleteTask => Icons.radio_button_unchecked,
      PlankaActionType.unknown => Icons.history,
    };

String _describe(AppLocalizations l10n, PlankaAction a) {
  final data = a.data ?? const {};
  String? str(String key) {
    final v = data[key];
    return v is String ? v : null;
  }

  // Planka action payloads nest names under data (e.g. data.list.name,
  // data.fromList/toList, data.user.name, data.task.name).
  String? nestedName(String key) {
    final v = data[key];
    return v is Map ? v['name'] as String? : null;
  }

  return switch (a.type) {
    PlankaActionType.createCard => switch (nestedName('list')) {
        final list? => l10n.activityCreatedCardInList(list),
        _ => l10n.activityCreatedCard,
      },
    PlankaActionType.moveCard =>
      switch ((nestedName('fromList'), nestedName('toList'))) {
        (final from?, final to?) => l10n.activityMovedCardFromTo(from, to),
        _ => l10n.activityMovedCard,
      },
    PlankaActionType.addMemberToCard =>
      l10n.activityAddedMember(nestedName('user') ?? l10n.activityAMember),
    PlankaActionType.removeMemberFromCard =>
      l10n.activityRemovedMember(nestedName('user') ?? l10n.activityAMember),
    PlankaActionType.completeTask => l10n.activityCompletedTask(
        nestedName('task') ?? str('name') ?? l10n.activityATask),
    PlankaActionType.uncompleteTask => l10n.activityUncompletedTask(
        nestedName('task') ?? str('name') ?? l10n.activityATask),
    PlankaActionType.unknown => l10n.activityUpdatedCard,
  };
}

class CardActivitySection extends ConsumerWidget {
  const CardActivitySection({
    super.key,
    required this.cardId,
    required this.users,
  });

  final String cardId;
  final List<PlankaUser> users;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(cardActionsProvider(cardId));
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return actions.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(l10n.activityLoadError,
          style: TextStyle(color: theme.colorScheme.error)),
      data: (items) {
        if (items.isEmpty) return Text(l10n.activityEmpty);
        final dateFormat = DateFormat.yMMMd().add_jm();
        return Column(
          children: [
            for (final a in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(_iconFor(a.type),
                    size: 20, color: theme.colorScheme.onSurfaceVariant),
                title: Text(
                  l10n.activityEntry(
                    users.where((u) => u.id == a.userId).firstOrNull?.name ??
                        l10n.activitySomeone,
                    _describe(l10n, a),
                  ),
                ),
                subtitle: a.createdAt == null
                    ? null
                    : Text(dateFormat.format(a.createdAt!.toLocal())),
              ),
          ],
        );
      },
    );
  }
}
