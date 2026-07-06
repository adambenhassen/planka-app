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
  'userUpdate',
];

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
    });
    socket.onDisconnect((_) => _connected.add(false));
    socket.on('connect_error', (_) => _connected.add(false));

    socket.connect();
  }

  /// Subscribes to realtime updates for [boardId]. The returned future always
  /// completes normally (never throws) — a failed/timed-out subscription is
  /// reported asynchronously as an error on the [events] stream, so callers
  /// observe failure there rather than by awaiting this method.
  Future<void> subscribeBoard(String boardId) async {
    _currentBoardId = boardId;
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    final ack = await socket
        .emitWithAckAsync(
          'get',
          sailsRequestFrame(
            method: 'get',
            url: '/api/boards/$boardId?subscribe=true',
            token: token,
          ),
        )
        .timeout(const Duration(seconds: 10),
            onTimeout: () => {'statusCode': 'timeout'});
    final status = ack is Map ? ack['statusCode'] : null;
    if (status != 200) {
      _events.addError(StateError('board subscribe failed: $ack'));
    }
  }

  void dispose() {
    _socket?.dispose();
    _events.close();
    _connected.close();
  }
}
