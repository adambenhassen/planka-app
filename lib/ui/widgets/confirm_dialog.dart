import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// Shows a yes/no confirmation dialog. Resolves to true only when the user taps
/// the confirm action; false on cancel or barrier dismiss. [cancelLabel]
/// defaults to the localized "Cancel", resolved from the dialog's context.
/// When [destructive] is true the confirm button is styled with the error color
/// pair so it reads as an unrecoverable action rather than a neutral save.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  Text(cancelLabel ?? AppLocalizations.of(ctx).actionCancel)),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
