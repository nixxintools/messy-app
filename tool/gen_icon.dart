// Generates the launcher icons: the yellow mesh-web on the app's dark
// background, matching lib/ui/widgets/web_logo.dart.
// Run: dart run tool/gen_icon.dart
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const yellow = (r: 0xFF, g: 0xD6, b: 0x0A);
const bg = (r: 0x0E, g: 0x11, b: 0x16);

/// Renders the web glyph: 3 rings + 8 spokes + center dot.
img.Image renderWeb({
  required int size,
  required double maxRadius,
  required double stroke,
  required bool opaqueBackground,
}) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  final c = size / 2;
  final rings = [maxRadius * 0.33, maxRadius * 0.66, maxRadius];
  final dotRadius = maxRadius * 0.09;

  bool onGlyph(double dx, double dy) {
    final dist = sqrt(dx * dx + dy * dy);
    if (dist > maxRadius + stroke) return false;
    if (dist <= dotRadius) return true;
    for (final r in rings) {
      if ((dist - r).abs() <= stroke / 2) return true;
    }
    for (var i = 0; i < 4; i++) {
      final a = i * pi / 4;
      final perp = (dx * sin(a) - dy * cos(a)).abs();
      if (perp <= stroke / 2 && dist <= maxRadius) return true;
    }
    return false;
  }

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final hit = onGlyph(x - c + 0.5, y - c + 0.5);
      if (hit) {
        image.setPixelRgba(x, y, yellow.r, yellow.g, yellow.b, 255);
      } else if (opaqueBackground) {
        image.setPixelRgba(x, y, bg.r, bg.g, bg.b, 255);
      } else {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
  return image;
}

void main() {
  Directory('assets/icon').createSync(recursive: true);

  // Full icon (legacy launchers): web fills most of the square on dark bg.
  final full = renderWeb(
    size: 1024,
    maxRadius: 400,
    stroke: 30,
    opaqueBackground: true,
  );
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(full));

  // Adaptive foreground: transparent, glyph inside the 66% safe zone.
  final fg = renderWeb(
    size: 1024,
    maxRadius: 280,
    stroke: 24,
    opaqueBackground: false,
  );
  File('assets/icon/icon_fg.png').writeAsBytesSync(img.encodePng(fg));

  stdout.writeln('Wrote assets/icon/icon.png and assets/icon/icon_fg.png');
}
