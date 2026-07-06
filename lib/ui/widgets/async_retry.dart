import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders an [AsyncValue]'s three states with the app's standard affordances:
/// loading -> centered spinner; error -> message plus a Retry button that calls
/// [onRetry]; data -> [data]. Keeps the loading/error scaffold in one place.
Widget asyncRetry<T>(
  AsyncValue<T> value,
  VoidCallback onRetry,
  Widget Function(T value) data,
) {
  return value.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$e'),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
    data: data,
  );
}
