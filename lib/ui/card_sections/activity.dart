import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api/models.dart';
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

String _describe(PlankaAction a) {
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
    PlankaActionType.createCard =>
      'created this card${nestedName('list') != null ? ' in ${nestedName('list')}' : ''}',
    PlankaActionType.moveCard =>
      'moved this card${nestedName('fromList') != null && nestedName('toList') != null ? ' from ${nestedName('fromList')} to ${nestedName('toList')}' : ''}',
    PlankaActionType.addMemberToCard =>
      'added ${nestedName('user') ?? 'a member'} to this card',
    PlankaActionType.removeMemberFromCard =>
      'removed ${nestedName('user') ?? 'a member'} from this card',
    PlankaActionType.completeTask =>
      'completed ${nestedName('task') ?? str('name') ?? 'a task'}',
    PlankaActionType.uncompleteTask =>
      'uncompleted ${nestedName('task') ?? str('name') ?? 'a task'}',
    PlankaActionType.unknown => 'updated this card',
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
    final theme = Theme.of(context);
    return actions.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Could not load activity',
          style: TextStyle(color: theme.colorScheme.error)),
      data: (items) {
        if (items.isEmpty) return const Text('No activity yet');
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
                  '${users.where((u) => u.id == a.userId).firstOrNull?.name ?? 'Someone'} '
                  '${_describe(a)}',
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
