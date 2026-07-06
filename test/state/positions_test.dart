import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/state/positions.dart';

void main() {
  test('empty list → gap', () => expect(positionBetween(null, null), 16384));
  test('append → last + gap', () => expect(positionBetween(32768, null), 49152));
  test('prepend → first / 2', () => expect(positionBetween(null, 16384), 8192));
  test('insert → midpoint', () => expect(positionBetween(16384, 32768), 24576));
}
