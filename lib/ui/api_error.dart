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
