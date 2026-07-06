import 'package:flutter/material.dart';

import '../api/planka_api.dart';

/// Single place all API errors surface to the user.
void showApiError(BuildContext context, Object error) {
  final message = switch (error) {
    ApiException(statusCode: 401) => 'Invalid credentials',
    ApiException(:final message) => message,
    _ => '$error',
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: Theme.of(context).colorScheme.error,
  ));
}

/// Runs an optimistic mutation and surfaces any failure via [showApiError].
/// Fire-and-forget: the caller has already applied the optimistic state, so
/// this only needs to report an error if the future rejects.
void guardMutation(BuildContext context, Future<void> future) {
  future.catchError((Object e) {
    if (context.mounted) showApiError(context, e);
  });
}
