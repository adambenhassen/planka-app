import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/planka_socket.dart';
import '../auth/auth_providers.dart';

/// The one socket joined to the signed-in user's own room (`user:<id>`).
///
/// Planka broadcasts a project's own events there rather than to a board room:
/// base custom field groups and the fields on them, notifications, the user
/// list. It is deliberately shared — a second socket would join the same room
/// and every event would then be handled twice — so anything needing a
/// user-scoped event listens to [userEventsProvider] instead of connecting a
/// socket of its own, and filters the stream down to the events it owns.
///
/// The provider is rebuilt whenever the current account changes, which disposes
/// the previous socket: signing out, signing back in and switching accounts
/// each leave exactly one subscription behind. A socket that drops rejoins the
/// room itself on reconnect.
final userSocketProvider = Provider<PlankaSocket?>((ref) {
  final account = ref.watch(currentAccountProvider);
  if (account == null) return null;
  final socket = PlankaSocket(account.serverUrl, account.token);
  ref.onDispose(socket.dispose);
  // subscribeUser is a no-op until the transport is up, and the socket re-issues
  // it from onConnect — so this covers both the first connect and every
  // reconnect. A failed subscribe surfaces as an error on the event stream.
  unawaited(socket.connect().then((_) => socket.subscribeUser()));
  return socket;
});

/// Events from the signed-in user's own room; empty while signed out.
final userEventsProvider = Provider<Stream<SocketEvent>>(
    (ref) => ref.watch(userSocketProvider)?.events ?? const Stream.empty());
