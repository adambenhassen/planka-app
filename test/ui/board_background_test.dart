import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/ui/widgets/board_background.dart';

void main() {
  test('gradient-type project resolves a gradient and no image', () {
    const p = PlankaProject(
        id: '1',
        name: 'P',
        backgroundType: 'gradient',
        backgroundGradient: 'jungle-mesh');
    final bg = resolveBoardBackground(p, const [], 'seed');
    expect(bg.imageUrl, isNull);
    expect(bg.gradient, isA<Gradient>());
  });

  test('image-type resolves the image url; large picks outside720', () {
    const img = PlankaBackgroundImage(id: 'img1', url: 'http://x/full.jpg', thumbnailUrls: {
      'outside720': 'http://x/720.jpg',
      'outside360': 'http://x/360.jpg',
    });
    const p = PlankaProject(
        id: '1', name: 'P', backgroundType: 'image', backgroundImageId: 'img1');
    expect(resolveBoardBackground(p, [img], 'seed', large: true).imageUrl,
        'http://x/720.jpg');
    expect(resolveBoardBackground(p, [img], 'seed').imageUrl, 'http://x/360.jpg');
  });

  test('image-type falls back to url when thumbnails absent', () {
    const img = PlankaBackgroundImage(id: 'img1', url: 'http://x/full.jpg');
    const p = PlankaProject(
        id: '1', name: 'P', backgroundType: 'image', backgroundImageId: 'img1');
    expect(resolveBoardBackground(p, [img], 'seed', large: true).imageUrl,
        'http://x/full.jpg');
  });

  test('no background and null project fall back to a gradient, no image', () {
    const p = PlankaProject(id: '1', name: 'P');
    expect(resolveBoardBackground(p, const [], 'seed').imageUrl, isNull);
    expect(resolveBoardBackground(null, const [], 'seed').imageUrl, isNull);
    expect(resolveBoardBackground(null, const [], 'seed').gradient, isA<Gradient>());
  });
}
