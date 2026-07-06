import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('parses board show envelope', () {
    final env = Envelope.parse(fixture('board_show'));
    expect(env.item['id'], isA<String>());
    expect(env.included.lists, isNotEmpty);
    expect(env.included.lists.first.name, 'To Do');
    expect(env.included.cards.first.position, greaterThan(0));
    expect(env.included.taskLists, isNotEmpty);
    expect(env.included.tasks, isNotEmpty);
    expect(env.included.labels.first.color, isNotEmpty);
  });

  test('parses projects index', () {
    final env = Envelope.parse(fixture('projects_index'));
    expect(env.items, isNotEmpty);
  });

  test('login item is raw jwt string', () {
    final json = fixture('login');
    expect(json['item'], isA<String>());
  });
}
