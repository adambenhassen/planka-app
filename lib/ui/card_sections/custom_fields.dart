import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/models.dart';
import '../card_sheet_edit_guard.dart';

/// The longest value the server stores — its create/update endpoint rejects
/// anything past it, so the field stops taking characters there.
const int kCustomFieldValueMaxLength = 512;

/// One custom field group's fields and this card's values.
class CardCustomFieldsSection extends StatelessWidget {
  const CardCustomFieldsSection({
    super.key,
    required this.entries,
    required this.onChanged,
    this.dismissalGuard,
  });

  /// The group's fields in position order, each with the card's value or null.
  final List<(PlankaCustomField, PlankaCustomFieldValue?)> entries;

  /// Hands a field its new content. Blank content clears the value: the server
  /// stores no empty string, so a cleared field is one that holds no value.
  final void Function(PlankaCustomField field, String content) onChanged;
  final CardSheetDismissalGuard? dismissalGuard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (field, value) in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                _CustomFieldValueField(
                  key: ValueKey('custom-field-${field.id}'),
                  id: field.id,
                  content: value?.content,
                  style: theme.textTheme.bodyMedium,
                  onSubmit: (content) => onChanged(field, content),
                  dismissalGuard: dismissalGuard,
                  accessibilityLabel: field.name,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The value line of one custom field, editable in place.
class _CustomFieldValueField extends StatefulWidget {
  const _CustomFieldValueField({
    super.key,
    required this.id,
    required this.content,
    required this.onSubmit,
    required this.dismissalGuard,
    required this.accessibilityLabel,
    this.style,
  });

  /// The value the server holds, or null when the field has none.
  final String id;
  final String? content;
  final ValueChanged<String> onSubmit;
  final CardSheetDismissalGuard? dismissalGuard;
  final String accessibilityLabel;
  final TextStyle? style;

  @override
  State<_CustomFieldValueField> createState() => _CustomFieldValueFieldState();
}

class _CustomFieldValueFieldState extends State<_CustomFieldValueField> {
  late final TextEditingController _controller;
  final _focus = FocusNode();
  late String _committedContent;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content ?? '')
      ..addListener(_onChanged);
    _committedContent = _normalise(widget.content);
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _CustomFieldValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content == oldWidget.content) return;
    // A value edited elsewhere, arriving over the socket. It takes the field
    // unless the user has changed the text — theirs is the edit about to be
    // submitted, and moving the caret out from under them would lose it.
    // Holding focus is not itself a change: a field tapped into and left alone
    // must still show what the other client wrote, or leaving it would hand
    // back a value nobody typed.
    if (!_dirty) {
      _committedContent = _normalise(widget.content);
      _controller.text = widget.content ?? '';
      _setDirty(false);
    }
  }

  @override
  void dispose() {
    // The listener goes before the node it is attached to.
    widget.dismissalGuard?.removeEditor('custom-field-${widget.id}', _focus);
    _focus.removeListener(_onFocusChanged);
    _controller.removeListener(_onChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    _notifyEditor();
    if (_focus.hasFocus) return;
    if (!(widget.dismissalGuard?.shouldCommitOnBlur ?? true)) return;
    _commit();
  }

  void _onChanged() =>
      _setDirty(_normalise(_controller.text) != _committedContent);

  void _setDirty(bool dirty) {
    if (_dirty == dirty) return;
    _dirty = dirty;
    _notifyEditor();
  }

  void _notifyEditor() {
    widget.dismissalGuard?.updateEditor(
      'custom-field-${widget.id}',
      _dirty,
      _focus,
      _focus.hasFocus,
    );
  }

  void _commit() {
    final content = _normalise(_controller.text);
    if (content == _committedContent) {
      if (_controller.text != content) _controller.text = content;
      _setDirty(false);
      return;
    }
    _committedContent = content;
    if (_controller.text != content) _controller.text = content;
    _setDirty(false);
    widget.onSubmit(content);
  }

  String _normalise(String? content) => content?.trim() ?? '';

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.accessibilityLabel,
    textField: true,
    child: TextField(
      controller: _controller,
      focusNode: _focus,
      style: widget.style,
      inputFormatters: [
        LengthLimitingTextInputFormatter(kCustomFieldValueMaxLength),
      ],
      decoration: const InputDecoration(isDense: true),
      onSubmitted: (_) => _focus.unfocus(),
    ),
  );
}
