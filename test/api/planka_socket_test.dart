import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/planka_socket.dart';

void main() {
  test('sails frame for board subscribe', () {
    final frame = sailsRequestFrame(
        method: 'get', url: '/api/boards/42?subscribe=true', token: 'jwt');
    expect(frame, {
      'method': 'get',
      'url': '/api/boards/42?subscribe=true',
      'headers': {'Authorization': 'Bearer jwt'},
      'data': {},
    });
  });

  test('SocketEvent parses item payload into envelope', () {
    final e = SocketEvent.parse('cardUpdate', {
      'item': {'id': 'c1', 'position': 8192}
    });
    expect(e.name, 'cardUpdate');
    expect(e.data.item['id'], 'c1');
  });

  test('SocketEvent tolerates non-map payload', () {
    final e = SocketEvent.parse('cardDelete', null);
    expect(e.data.item, isEmpty);
    expect(e.data.items, isEmpty);
  });

  test('event name list covers create/update/delete families', () {
    for (final family in ['card', 'list', 'label', 'comment', 'task']) {
      expect(kPlankaSocketEvents, contains('${family}Create'));
      expect(kPlankaSocketEvents, contains('${family}Update'));
      expect(kPlankaSocketEvents, contains('${family}Delete'));
    }
    expect(kPlankaSocketEvents, contains('cardsUpdate'));
    expect(kPlankaSocketEvents, contains('listClear'));
  });
}
