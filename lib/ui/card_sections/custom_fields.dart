import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/models.dart';

/// The longest value the server stores — its create/update endpoint rejects
/// anything past it, so the field stops taking characters there.
const int kCustomFieldValueMaxLength = 512;

/// One custom field group's fields and this card's values.
class CardCustomFieldsSection extends StatelessWidget {
  const CardCustomFieldsSection({
    super.key,
    required this.entries,
    required this.onChanged,
  });

  /// The group's fields in position order, each with the card's value or null.
  final List<(PlankaCustomField, PlankaCustomFieldValue?)> entries;

  /// Hands a field its new content. Blank content clears the value: the server
  /// stores no empty string, so a cleared field is one that holds no value.
  final void Function(PlankaCustomField field, String content) onChanged;

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
                Text(field.name,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                _CustomFieldValueField(
                  key: ValueKey('custom-field-${field.id}'),
                  content: value?.content,
                  style: theme.textTheme.bodyMedium,
                  onSubmit: (content) => onChanged(field, content),
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
    required this.content,
    required this.onSubmit,
    this.style,
  });

  /// The value the server holds, or null when the field has none.
  final String? content;
  final ValueChanged<String> onSubmit;
  final TextStyle? style;

  @override
  State<_CustomFieldValueField> createState() => _CustomFieldValueFieldState();
}

class _CustomFieldValueFieldState extends State<_CustomFieldValueField> {
  late final _controller = TextEditingController(text: widget.content ?? '');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _CustomFieldValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A value edited elsewhere, arriving over the socket. A field the user is
    // typing in keeps what they typed — that edit is the one about to be
    // submitted, and taking the caret away mid-word is worse than being stale
    // for a moment.
    if (widget.content != oldWidget.content && !_focus.hasFocus) {
      _controller.text = widget.content ?? '';
    }
  }

  @override
  void dispose() {
    // The listener goes before the node it is attached to.
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) return;
    final content = _controller.text.trim();
    // Leaving a field alone writes nothing, so opening a card and scrolling
    // past its custom fields costs no requests.
    if (content == (widget.content ?? '')) return;
    widget.onSubmit(content);
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        focusNode: _focus,
        style: widget.style,
        inputFormatters: [
          LengthLimitingTextInputFormatter(kCustomFieldValueMaxLength),
        ],
        decoration: const InputDecoration(isDense: true),
        // Enter submits by dropping focus rather than by its own path, so the
        // edit is handed in exactly once however the field is left.
        onSubmitted: (_) => _focus.unfocus(),
      );
}
