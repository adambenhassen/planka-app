import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// Prompts for a single line of text. Returns the trimmed value, or null on
/// cancel or empty input. [confirmLabel] defaults to the localized "Save",
/// resolved from the dialog's context.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String? initialValue,
  String? hintText,
  String? confirmLabel,
}) async {
  final value = await showDialog<String>(
    context: context,
    builder: (ctx) => _PromptDialog(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      confirmLabel: confirmLabel ?? AppLocalizations.of(ctx).actionSave,
    ),
  );
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// Stateful so the [TextEditingController] is owned and disposed with the
/// dialog's route, not before its exit animation finishes.
class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.confirmLabel,
  });

  final String title;
  final String? initialValue;
  final String? hintText;
  final String confirmLabel;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hintText),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
