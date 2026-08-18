import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test_driver_extended.dart';

/// Empty status-bar strip at the top of simulator captures, in logical px
/// (iPhone 16 Pro safe-area top). Multiplied by the device pixel ratio.
const _statusBarLogicalPx = 62;
const _devicePixelRatio = 3;
const _cornerRadius = 72;

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes,
        [Map<String, Object?>? args]) async {
      final decoded = img.decodePng(Uint8List.fromList(bytes));
      if (decoded == null) {
        stderr.writeln('screenshot $name: could not decode PNG');
        return false;
      }
      final polished = _polish(decoded);
      final file = File('.github/assets/screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(img.encodePng(polished));
      return true;
    },
  );
}

/// Crops the blank status-bar strip and rounds the corners (transparent).
img.Image _polish(img.Image src) {
  final top = _statusBarLogicalPx * _devicePixelRatio;
  final cropped = img.copyCrop(src,
      x: 0, y: top, width: src.width, height: src.height - top);
  final out = img.Image(
      width: cropped.width, height: cropped.height, numChannels: 4);
  final r = _cornerRadius;
  for (final p in cropped) {
    final x = p.x, y = p.y;
    final w = cropped.width, h = cropped.height;
    // Distance from the nearest corner centre; outside the radius → transparent.
    final cx = x < r ? r : (x >= w - r ? w - r - 1 : x);
    final cy = y < r ? r : (y >= h - r ? h - r - 1 : y);
    final dx = x - cx, dy = y - cy;
    final inside = dx * dx + dy * dy <= r * r;
    out.setPixelRgba(x, y, p.r, p.g, p.b, inside ? 255 : 0);
  }
  return out;
}
