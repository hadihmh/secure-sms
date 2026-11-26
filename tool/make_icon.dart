// Draws the app icon and writes every Android/iOS launcher size.
// Run: flutter test tool/make_icon.dart
// Then strip alpha from the iOS PNGs (App Store rejects it), e.g. a sips JPEG → PNG round trip.
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

const _bg1 = Color(0xFF131A22), _bg2 = Color(0xFF0B0F14);
const _mint = Color(0xFF4DE3B5), _ink = Color(0xFF04221A);

/// Mint speech bubble holding a padlock, on the app's dark background.
Picture _paint(double s) {
  final r = PictureRecorder();
  final c = Canvas(r);
  final u = s / 100; // design on a 100-unit grid
  c.drawRect(
    Rect.fromLTWH(0, 0, s, s),
    Paint()..shader = Gradient.linear(Offset.zero, Offset(s, s), [_bg1, _bg2]),
  );
  final mint = Paint()..color = _mint;
  // Bubble + tail (bottom start, like a chat bubble).
  c.drawRRect(
    RRect.fromLTRBR(18 * u, 20 * u, 82 * u, 72 * u, Radius.circular(16 * u)),
    mint,
  );
  c.drawPath(
    Path()
      ..moveTo(28 * u, 66 * u)
      ..lineTo(24 * u, 84 * u)
      ..lineTo(44 * u, 70 * u)
      ..close(),
    mint,
  );
  // Padlock: shackle, body, keyhole.
  final ink = Paint()..color = _ink;
  c.drawArc(
    Rect.fromLTRB(40 * u, 28 * u, 60 * u, 50 * u),
    3.14159,
    3.14159,
    false,
    Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * u,
  );
  c.drawRect(Rect.fromLTRB(37.5 * u, 39 * u, 42.5 * u, 46 * u), ink);
  c.drawRect(Rect.fromLTRB(57.5 * u, 39 * u, 62.5 * u, 46 * u), ink);
  c.drawRRect(
    RRect.fromLTRBR(34 * u, 44 * u, 66 * u, 64 * u, Radius.circular(4 * u)),
    ink,
  );
  c.drawCircle(Offset(50 * u, 52 * u), 3.2 * u, mint);
  c.drawRect(Rect.fromLTRB(48.6 * u, 52 * u, 51.4 * u, 58 * u), mint);
  return r.endRecording();
}

Future<void> _write(String path, int px) async {
  final img = await _paint(px.toDouble()).toImage(px, px);
  final png = await img.toByteData(format: ImageByteFormat.png);
  File(path).writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test('write launcher icons', () async {
    const android = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final e in android.entries) {
      await _write(
        'android/app/src/main/res/mipmap-${e.key}/ic_launcher.png',
        e.value,
      );
    }
    final ios = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    final name = RegExp(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png$');
    for (final f in ios.listSync().whereType<File>()) {
      final m = name.firstMatch(f.path);
      if (m != null) {
        await _write(f.path, (double.parse(m[1]!) * int.parse(m[2]!)).round());
      }
    }
  });
}
