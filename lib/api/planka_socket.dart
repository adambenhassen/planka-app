import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'envelope.dart';
import 'planka_api.dart';

/// Planka server-push event names (verbatim).
const kPlankaSocketEvents = [
  'boardUpdate', 'boardDelete',
  'listCreate', 'listUpdate', 'listDelete', 'listClear',
  'labelCreate', 'labelUpdate', 'labelDelete',
  'cardCreate', 'cardUpdate', 'cardDelete', 'cardsUpdate',
  'cardMembershipCreate', 'cardMembershipDelete',
  'cardLabelCreate', 'cardLabelDelete',
  'taskListCreate', 'taskListUpdate', 'taskListDelete',
  'taskCreate', 'taskUpdate', 'taskDelete',
  'attachmentCreate', 'attachmentUpdate', 'attachmentDelete',
  'commentCreate', 'commentUpdate', 'commentDelete',
  'notificationCreate', 'notificationUpdate',
  'boardMembershipCreate', 'boardMembershipUpdate', 'boardMembershipDelete',
  'actionCreate',
  'userUpdate',
  'customFieldGroupCreate', 'customFieldGroupUpdate', 'customFieldGroupDelete',
  // A field on a project's base group reuses these names; only the room it
  // arrives on differs, so there is no baseCustomField* family.
  'customFieldCreate', 'customFieldUpdate', 'customFieldDelete',
  'baseCustomFieldGroupCreate', 'baseCustomFieldGroupUpdate',
  'baseCustomFieldGroupDelete',
  // No create event: one endpoint creates and updates a value, and the server
  // broadcasts customFieldValueUpdate for both.
  'customFieldValueUpdate', 'customFieldValueDelete',
];

/// The sails route that joins the signed-in user's own room. Planka broadcasts
/// project-level events there rather than to any board room.
const kUserSubscribeUrl = '/api/users/me?subscribe=true';

class SocketEvent {
  final String name;
  final Envelope data;
  SocketEvent(this.name, this.data);

  factory SocketEvent.parse(String name, dynamic payload) => SocketEvent(
      name,
      Envelope.parse(
          payload is Map ? payload.cast<String, dynamic>() : const {}));
}

/// sails.io.js virtual request frame.
Map<String, dynamic> sailsRequestFrame({
  required String method,
  required String url,
  required String token,
  Map<String, dynamic>? data,
}) =>
    {
      'method': method,
      'url': url,
      'headers': {'Authorization': bearerAuth(token)},
      'data': data ?? {},
    };

class PlankaSocket {
  final String serverUrl;
  final String token;
  io.Socket? _socket;
  String? _currentBoardId;

  /// Set once [subscribeUser] has been called, so a reconnect rejoins the room
  /// rather than leaving it silently lost.
  bool _userSubscribed = false;

  final _events = StreamController<SocketEvent>.broadcast();
  final _connected = StreamController<bool>.broadcast();

  PlankaSocket(this.serverUrl, this.token);

  /// Raw socket, exposed for diagnostics (dev probe) only.
  io.Socket? get debugSocket => _socket;

  Stream<SocketEvent> get events => _events.stream;
  Stream<bool> get connected => _connected.stream;

  Future<void> connect() async {
    final socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setPath('/socket.io')
          .setTransports(['websocket'])
          // sails rejects handshakes without the sails.io.js SDK version.
          .setQuery({
            '__sails_io_sdk_version': '1.2.1',
            '__sails_io_sdk_platform': 'browser',
            '__sails_io_sdk_language': 'javascript',
          })
          // sails checks Origin; non-browser clients must send it explicitly.
          .setExtraHeaders({'Origin': serverUrl})
          .disableAutoConnect()
          .build(),
    );
    _socket = socket;

    for (final name in kPlankaSocketEvents) {
      socket.on(name, (payload) => _events.add(SocketEvent.parse(name, payload)));
    }
    socket.onConnect((_) {
      _connected.add(true);
      final boardId = _currentBoardId;
      if (boardId != null) subscribeBoard(boardId);
      if (_userSubscribed) subscribeUser();
    });
    socket.onDisconnect((_) => _connected.add(false));
    socket.on('connect_error', (_) => _connected.add(false));

    socket.connect();
  }

  /// Subscribes to realtime updates for [boardId]. The returned future always
  /// completes normally (never throws) — a failed/timed-out subscription is
  /// reported asynchronously as an error on the [events] stream, so callers
  /// observe failure there rather than by awaiting this method.
  Future<void> subscribeBoard(String boardId) {
    _currentBoardId = boardId;
    return _subscribe('board', '/api/boards/$boardId?subscribe=true');
  }

  /// Subscribes to the signed-in user's own room, which carries the
  /// project-level events no board room does. Joining is idempotent on the
  /// server and one join feeds every listener on [events], so subscribe once
  /// per socket rather than opening a second socket for another event family.
  /// Failure is reported on [events] exactly as for [subscribeBoard].
  Future<void> subscribeUser() {
    _userSubscribed = true;
    return _subscribe('user', kUserSubscribeUrl);
  }

  /// Issues one sails subscribe request. Does nothing while disconnected — the
  /// onConnect handler re-issues whatever was asked for.
  ///
  /// A rejected or timed-out ack leaves the room silently unjoined while the
  /// transport stays up — no disconnect follows, so nothing re-issues the join
  /// by itself. Retry with backoff before reporting failure on [events], so a
  /// blip costs a second rather than the session's realtime.
  Future<void> _subscribe(String room, String url) async {
    Object? ack;
    var delay = const Duration(seconds: 1);
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(delay);
        delay *= 2;
      }
      final socket = _socket;
      if (socket == null || !socket.connected) return;
      try {
        ack = await socket
            .emitWithAckAsync(
              'get',
              sailsRequestFrame(method: 'get', url: url, token: token),
            )
            .timeout(const Duration(seconds: 10),
                onTimeout: () => {'statusCode': 'timeout'});
      } catch (e) {
        // A transport error (disconnect mid-request, disposed socket) counts
        // as a failed attempt — it must not escape as an unhandled async
        // error from the unawaited calls above.
        ack = e;
      }
      if (ack is Map && ack['statusCode'] == 200) return;
    }
    if (_events.isClosed) return;
    _events.addError(StateError('$room subscribe failed: $ack'));
  }

  void dispose() {
    _socket?.dispose();
    _events.close();
    _connected.close();
  }
}
