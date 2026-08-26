import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../api/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../card_sheet_edit_guard.dart';

class CardHeaderSection extends StatefulWidget {
  const CardHeaderSection({
    super.key,
    required this.card,
    required this.onRename,
    required this.onDescriptionChanged,
    this.dismissalGuard,
  });

  final PlankaCard card;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onDescriptionChanged;
  final CardSheetDismissalGuard? dismissalGuard;

  @override
  State<CardHeaderSection> createState() => _CardHeaderSectionState();
}

class _CardHeaderSectionState extends State<CardHeaderSection> {
  late final TextEditingController _titleController;
  late final FocusNode _titleFocus;
  late final TextEditingController _descriptionController;
  late final FocusNode _descriptionFocus;
  bool _editingDescription = false;
  late String _committedTitle;
  late String _committedDescription;
  bool _titleDirty = false;
  bool _descriptionDirty = false;

  @override
  void initState() {
    super.initState();
    _committedTitle = widget.card.name;
    _committedDescription = widget.card.description ?? '';
    _titleController = TextEditingController(text: _committedTitle)
      ..addListener(_onTitleChanged);
    _descriptionController = TextEditingController(text: _committedDescription)
      ..addListener(_onDescriptionChanged);
    _titleFocus = FocusNode()..addListener(_onTitleFocusChanged);
    _descriptionFocus = FocusNode()..addListener(_onDescriptionFocusChanged);
  }

  @override
  void didUpdateWidget(covariant CardHeaderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.card.name != oldWidget.card.name && !_titleDirty) {
      _committedTitle = widget.card.name;
      _titleController.value = TextEditingValue(text: _committedTitle);
    }

    final description = widget.card.description ?? '';
    final oldDescription = oldWidget.card.description ?? '';
    if (description != oldDescription && !_descriptionDirty) {
      _committedDescription = description;
      _descriptionController.value = TextEditingValue(text: description);
    }
  }

  @override
  void dispose() {
    widget.dismissalGuard?.removeEditor('title', _titleFocus);
    widget.dismissalGuard?.removeEditor('description', _descriptionFocus);
    _titleController.removeListener(_onTitleChanged);
    _descriptionController.removeListener(_onDescriptionChanged);
    _titleFocus.removeListener(_onTitleFocusChanged);
    _descriptionFocus.removeListener(_onDescriptionFocusChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _notifyEditor(String id, bool dirty, FocusNode focus) {
    widget.dismissalGuard?.updateEditor(id, dirty, focus, focus.hasFocus);
  }

  void _setTitleDirty(bool dirty) {
    if (_titleDirty == dirty) return;
    _titleDirty = dirty;
    _notifyEditor('title', dirty, _titleFocus);
  }

  void _setDescriptionDirty(bool dirty) {
    if (_descriptionDirty == dirty) return;
    _descriptionDirty = dirty;
    _notifyEditor('description', dirty, _descriptionFocus);
  }

  void _onTitleChanged() {
    _setTitleDirty(_titleController.text.trim() != _committedTitle.trim());
  }

  void _onDescriptionChanged() {
    _setDescriptionDirty(_descriptionController.text != _committedDescription);
  }

  void _onTitleFocusChanged() {
    _notifyEditor('title', _titleDirty, _titleFocus);
    if (!_titleFocus.hasFocus) _commitTitle();
  }

  void _onDescriptionFocusChanged() {
    _notifyEditor('description', _descriptionDirty, _descriptionFocus);
    if (!_descriptionFocus.hasFocus) _commitDescription();
  }

  void _commitTitle() {
    if (!(widget.dismissalGuard?.shouldCommitOnBlur ?? true)) return;
    final name = _titleController.text.trim();
    if (name == _committedTitle.trim()) {
      if (_titleController.text != name) {
        _titleController.value = TextEditingValue(text: name);
      }
      _committedTitle = name;
      _setTitleDirty(false);
      return;
    }
    // The server rejects an empty card name. Keep it dirty so leaving the
    // sheet still explains that the attempted edit would be lost.
    if (name.isEmpty) return;
    _committedTitle = name;
    if (_titleController.text != name) {
      _titleController.value = TextEditingValue(text: name);
    }
    _setTitleDirty(false);
    widget.onRename(name);
  }

  void _commitDescription() {
    if (!(widget.dismissalGuard?.shouldCommitOnBlur ?? true)) return;
    final description = _descriptionController.text;
    if (description == _committedDescription) {
      _setDescriptionDirty(false);
      return;
    }
    _committedDescription = description;
    _setDescriptionDirty(false);
    widget.onDescriptionChanged(description);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final description = widget.card.description ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: l10n.cardNameHint,
          textField: true,
          child: TextFormField(
            key: ValueKey('title-${widget.card.id}'),
            controller: _titleController,
            focusNode: _titleFocus,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: const InputDecoration(border: InputBorder.none),
            onFieldSubmitted: (_) => _commitTitle(),
          ),
        ),
        if (_editingDescription)
          Semantics(
            label: l10n.cardDescriptionHint,
            textField: true,
            child: TextFormField(
              key: ValueKey('desc-${widget.card.id}'),
              controller: _descriptionController,
              focusNode: _descriptionFocus,
              autofocus: true,
              maxLines: null,
              minLines: 2,
              decoration: InputDecoration(
                hintText: l10n.cardDescriptionHint,
                border: InputBorder.none,
              ),
              onFieldSubmitted: (_) {
                _commitDescription();
                if (mounted) setState(() => _editingDescription = false);
              },
            ),
          )
        else
          // Rendered markdown; tap to switch into the plain-text editor.
          InkWell(
            onTap: () => setState(() => _editingDescription = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: description.isEmpty
                  ? Text(
                      l10n.cardDescriptionHint,
                      style: TextStyle(color: Theme.of(context).hintColor),
                    )
                  : MarkdownBody(data: description),
            ),
          ),
      ],
    );
  }
}
