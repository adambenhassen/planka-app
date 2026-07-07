import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/ui/theme/planka_gradients.dart';

// The 25 gradient names Planka's API can return (client/src/constants/
// BackgroundGradients). Every one must resolve, or a board silently loses its
// server-set background.
const _plankaNames = [
  'old-lime', 'ocean-dive', 'tzepesch-style', 'jungle-mesh', 'strawberry-dust',
  'purple-rose', 'sun-scream', 'warm-rust', 'sky-change', 'green-eyes',
  'blue-xchange', 'blood-orange', 'sour-peel', 'green-ninja', 'algae-green',
  'coral-reef', 'steel-grey', 'heat-waves', 'velvet-lounge', 'purple-rain',
  'blue-steel', 'blueish-curve', 'prism-light', 'green-mist', 'red-curtain',
];

void main() {
  test('every Planka gradient name resolves to a gradient', () {
    for (final name in _plankaNames) {
      expect(plankaGradient(name), isA<Gradient>(), reason: name);
    }
  });

  test('unknown gradient name resolves to null', () {
    expect(plankaGradient('not-a-gradient'), isNull);
    expect(plankaGradient(null), isNull);
  });

  test('projectGradient only renders gradient-type backgrounds', () {
    expect(projectGradient('gradient', 'jungle-mesh'), isA<Gradient>());
    // Image backgrounds and no-background fall back (null → caller uses a color).
    expect(projectGradient('image', null), isNull);
    expect(projectGradient(null, null), isNull);
    // Gradient type with an unknown name is null, not a crash.
    expect(projectGradient('gradient', 'bogus'), isNull);
  });
}
