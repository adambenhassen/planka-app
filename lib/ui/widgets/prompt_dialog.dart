import 'package:flutter/material.dart';

/// Prompts for a single line of text. Returns the trimmed value, or null on
/// cancel or empty input.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String? initialValue,
  String? hintText,
  String confirmLabel = 'Save',
}) async {
  final controller = TextEditingController(text: initialValue);
  final value = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hintText),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
