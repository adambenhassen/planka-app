import 'package:flutter/material.dart';

/// A compact "+ [label]" button that swaps into an autofocused text field and
/// submits the trimmed text ([onSubmit]); an empty value just cancels. When
/// [columnWidth] is set it lays out as a fixed-width board column, otherwise it
/// fills its parent. Error handling for [onSubmit] belongs to the caller.
class InlineAddField extends StatefulWidget {
  const InlineAddField({
    super.key,
    required this.label,
    required this.onSubmit,
    String? hintText,
    this.columnWidth,
  }) : hintText = hintText ?? label;

  final String label;
  final String hintText;
  final ValueChanged<String> onSubmit;
  final double? columnWidth;

  @override
  State<InlineAddField> createState() => _InlineAddFieldState();
}

class _InlineAddFieldState extends State<InlineAddField> {
  bool _editing = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    setState(() => _editing = false);
    if (text.isEmpty) return;
    _ctrl.clear();
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final child = _editing
        ? Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _submit(),
              onTapOutside: (_) => _submit(),
            ),
          )
        : TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: Text(widget.label),
            onPressed: () => setState(() => _editing = true),
          );
    if (widget.columnWidth == null) return child;
    return Container(
      width: widget.columnWidth,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}
