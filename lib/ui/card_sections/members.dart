import 'package:flutter/material.dart';

import '../../api/models.dart';

class CardMembersSection extends StatelessWidget {
  const CardMembersSection({
    super.key,
    required this.boardUsers,
    required this.memberUserIds,
    required this.onToggle,
  });

  final List<PlankaUser> boardUsers;
  final Set<String> memberUserIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final u in boardUsers)
          FilterChip(
            avatar: CircleAvatar(
              radius: 12,
              child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase()),
            ),
            label: Text(u.name),
            selected: memberUserIds.contains(u.id),
            onSelected: (_) => onToggle(u.id),
          ),
      ],
    );
  }
}
