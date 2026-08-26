import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../card_sheet_edit_guard.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/prompt_dialog.dart';

class CardCommentsSection extends StatefulWidget {
  const CardCommentsSection({
    super.key,
    required this.comments,
    required this.users,
    required this.currentUserId,
    required this.onSend,
    required this.onEdit,
    required this.onDelete,
    this.dismissalGuard,
  });

  final List<PlankaComment> comments; // newest last
  final List<PlankaUser> users;
  final String currentUserId;
  final ValueChanged<String> onSend;
  final void Function(String id, String text) onEdit;
  final ValueChanged<String> onDelete;
  final CardSheetDismissalGuard? dismissalGuard;

  @override
  State<CardCommentsSection> createState() => _CardCommentsSectionState();
}

class _CardCommentsSectionState extends State<CardCommentsSection> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onComposerChanged);
    _focus.addListener(_onComposerFocusChanged);
  }

  @override
  void dispose() {
    widget.dismissalGuard?.removeEditor('comment', _focus);
    _ctrl.removeListener(_onComposerChanged);
    _focus.removeListener(_onComposerFocusChanged);
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onComposerChanged() {
    widget.dismissalGuard?.updateEditor(
      'comment',
      _ctrl.text.isNotEmpty,
      _focus,
      _focus.hasFocus,
    );
  }

  void _onComposerFocusChanged() {
    _onComposerChanged();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.comments.map((c) {
          final name = _userName(c.userId);
          final isOwn = c.userId == widget.currentUserId;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: theme.textTheme.labelLarge),
                          const SizedBox(width: 8),
                          if (c.createdAt != null)
                            Text(
                              DateFormat.MMMd().add_Hm().format(
                                c.createdAt!.toLocal(),
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      Text(c.text),
                    ],
                  ),
                ),
                if (isOwn)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (action) async {
                      if (action == 'edit') {
                        final text = await promptText(
                          context,
                          title: l10n.commentEditTitle,
                          initialValue: c.text,
                        );
                        if (!context.mounted || text == null) return;
                        widget.onEdit(c.id, text);
                      } else if (action == 'delete') {
                        if (await confirmDialog(
                          context,
                          title: l10n.commentDeleteTitle,
                          confirmLabel: l10n.actionDelete,
                        )) {
                          widget.onDelete(c.id);
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.actionEdit),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.actionDelete),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                decoration: InputDecoration(
                  hintText: l10n.commentHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              tooltip: l10n.commentSend,
              onPressed: _send,
            ),
          ],
        ),
      ],
    );
  }

  String _userName(String userId) =>
      widget.users.where((u) => u.id == userId).firstOrNull?.name ?? '';
}
