import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/state/envelope_cache.dart';

const _boardId = '1844338624586318868';

final _account = Account(
  serverUrl: 'https://planka.example.com',
  token: 'tok',
  userId: 'u1',
  displayName: 'Test',
);

class _FixedAccount extends CurrentAccountNotifier {
  @override
  Account build() => _account;
}

class _FakeApi extends PlankaApi {
  _FakeApi() : super('https://planka.example.com', 'tok');

  Completer<void>? gate;
  var boardName = 'Fresh Board';

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    final pending = gate;
    if (pending != null) await pending.future;
    final json = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    (json['item'] as Map<String, dynamic>)['name'] = boardName;
    return Envelope.parse(json);
  }
}

class _LoadingNotifier extends BoardNotifier {
  _LoadingNotifier(super.boardId);

  @override
  Future<BoardState> build() => load();
}

void main() {
  test('renders cached board before the refresh and reconciles it', () async {
    final dir = Directory.systemTemp.createTempSync('board_cache_first');
    addTearDown(() => dir.deleteSync(recursive: true));
    final cachedJson = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    (cachedJson['item'] as Map<String, dynamic>)['name'] = 'Cached Board';
    await EnvelopeCache(directory: dir).put(
      '${_account.id}-board-$_boardId',
      Envelope.parse(cachedJson),
    );

    final api = _FakeApi()..gate = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(api),
        currentAccountProvider.overrideWith(_FixedAccount.new),
        envelopeCacheProvider.overrideWithValue(EnvelopeCache(directory: dir)),
        boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
      ],
    );
    addTearDown(container.dispose);
    final provider = boardProvider(_boardId);
    container.read(provider);

    for (var i = 0; i < 100 && container.read(provider).value == null; i++) {
      await container.pump();
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }

    final cachedState = container.read(provider);
    expect(cachedState.value!.board.name, 'Cached Board');
    expect(cachedState.value!.isStale, isTrue);

    api.boardName = 'Fresh Board';
    api.gate!.complete();
    await container.read(provider.future);

    final freshState = container.read(provider);
    expect(freshState.value!.board.name, 'Fresh Board');
    expect(freshState.value!.isStale, isFalse);
  });
}
