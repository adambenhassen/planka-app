import 'package:flutter/material.dart';

/// Shows a yes/no confirmation dialog. Resolves to true only when the user taps
/// the confirm action; false on cancel or barrier dismiss.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel)),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel)),
      ],
    ),
  );
  return confirmed ?? false;
}
