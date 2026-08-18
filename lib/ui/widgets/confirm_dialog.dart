import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// Shows a yes/no confirmation dialog. Resolves to true only when the user taps
/// the confirm action; false on cancel or barrier dismiss. [cancelLabel]
/// defaults to the localized "Cancel", resolved from the dialog's context.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String? cancelLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel ?? AppLocalizations.of(ctx).actionCancel)),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel)),
      ],
    ),
  );
  return confirmed ?? false;
}
