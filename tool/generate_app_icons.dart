import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  final srcFile = File('gorsel/app_icon.png');
  if (!srcFile.existsSync()) {
    stderr.writeln('gorsel/app_icon.png not found!');
    exit(1);
  }

  final src = img.decodeImage(srcFile.readAsBytesSync())!;
  final w = src.width;
  final h = src.height;
  final cx = w / 2.0;
  final cy = h / 2.0;

  // In gorsel/app_icon.png (1024x1024):
  // All artwork (castle, mosque, GEBZE DİJİTAL, bottom cyan bar, and inner glow)
  // is inside r <= 484px.
  // Between r = 486..498px is a dark outer shadow ring, and r > 498px is the dark corner fill.
  // For any pixel with r <= 482px, we sample the exact source pixel (100% unstretched!).
  // For r > 482px, we smoothly transition to a clean vertical sky/navy ambient gradient
  // (matching the badge's own palette) so there are NO dark/black corners and NO radial streaks!
  const double badgeRadius = 482.0;

  (int, int, int) ambientColorAt(double sx, double sy) {
    final t = (sy / h).clamp(0.0, 1.0);
    // Top: bright Gebze sky blue (#28629B) -> Mid: warm horizon blue (#1A4980) -> Bottom: Gebze navy (#0C2B5E)
    final double r, g, b;
    if (t < 0.5) {
      final k = t / 0.5;
      r = 40 + (26 - 40) * k;
      g = 98 + (73 - 98) * k;
      b = 155 + (128 - 155) * k;
    } else {
      final k = (t - 0.5) / 0.5;
      r = 26 + (12 - 26) * k;
      g = 73 + (43 - 73) * k;
      b = 128 + (94 - 128) * k;
    }
    return (r.round(), g.round(), b.round());
  }

  (int, int, int) sampleClean(double sx, double sy) {
    final dx = sx - cx;
    final dy = sy - cy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist <= badgeRadius - 6.0) {
      final px = sx.round().clamp(0, w - 1);
      final py = sy.round().clamp(0, h - 1);
      final p = src.getPixel(px, py);
      return (p.r.toInt(), p.g.toInt(), p.b.toInt());
    } else if (dist <= badgeRadius) {
      final px = sx.round().clamp(0, w - 1);
      final py = sy.round().clamp(0, h - 1);
      final p = src.getPixel(px, py);
      final (ar, ag, ab) = ambientColorAt(sx, sy);
      final k = (dist - (badgeRadius - 6.0)) / 6.0;
      return (
        (p.r * (1 - k) + ar * k).round(),
        (p.g * (1 - k) + ag * k).round(),
        (p.b * (1 - k) + ab * k).round(),
      );
    } else {
      return ambientColorAt(sx, sy);
    }
  }

  // 1. Adaptive Icon Foreground (108dp canvas, 72dp visible mask = 66.67% diameter)
  // By mapping badgeRadius (482px) to 0.365 of the 108dp canvas (73% diameter = 78.8dp),
  // the circular badge completely fills the 72dp circle/squircle/rounded-square mask on all phones
  // with zero black border, while keeping all text and logos comfortably inside the safe zone!
  img.Image buildAdaptiveForeground(int targetSize) {
    final out = img.Image(width: targetSize, height: targetSize, numChannels: 4);
    final tcx = targetSize / 2.0;
    final tcy = targetSize / 2.0;
    final scale = badgeRadius / (targetSize * 0.365);

    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        final sx = cx + (x + 0.5 - tcx) * scale;
        final sy = cy + (y + 0.5 - tcy) * scale;
        final (r, g, b) = sampleClean(sx, sy);
        out.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return out;
  }

  // 2. Legacy Round Icon (100% circle filling the entire canvas, transparent outside)
  img.Image buildRoundIcon(int targetSize) {
    final out = img.Image(width: targetSize, height: targetSize, numChannels: 4);
    final tcx = targetSize / 2.0;
    final tcy = targetSize / 2.0;
    final maxR = targetSize / 2.0;
    final scale = badgeRadius / maxR;

    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        final dx = (x + 0.5) - tcx;
        final dy = (y + 0.5) - tcy;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist > maxR) {
          out.setPixelRgba(x, y, 0, 0, 0, 0);
          continue;
        }
        final sx = cx + dx * scale;
        final sy = cy + dy * scale;
        final (r, g, b) = sampleClean(sx, sy);
        double alpha = 1.0;
        if (dist > maxR - 1.5) {
          alpha = ((maxR - dist) / 1.5).clamp(0.0, 1.0);
        }
        out.setPixelRgba(x, y, r, g, b, (alpha * 255).round());
      }
    }
    return out;
  }

  // 3. Legacy Square / Squircle Icon
  img.Image buildSquareIcon(int targetSize, {bool roundedCorners = false}) {
    final out = img.Image(width: targetSize, height: targetSize, numChannels: 4);
    final tcx = targetSize / 2.0;
    final tcy = targetSize / 2.0;
    final half = targetSize / 2.0;
    final scale = badgeRadius / half;
    final cornerR = targetSize * 0.21;

    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        double alpha = 1.0;
        if (roundedCorners) {
          final qx = (x + 0.5 - tcx).abs() - (half - cornerR);
          final qy = (y + 0.5 - tcy).abs() - (half - cornerR);
          final d = math.sqrt(math.max(qx, 0.0) * math.max(qx, 0.0) +
                  math.max(qy, 0.0) * math.max(qy, 0.0)) +
              math.min(math.max(qx, qy), 0.0) -
              cornerR;
          if (d > 0) {
            out.setPixelRgba(x, y, 0, 0, 0, 0);
            continue;
          }
          if (d > -1.5) {
            alpha = (-d / 1.5).clamp(0.0, 1.0);
          }
        }
        final sx = cx + (x + 0.5 - tcx) * scale;
        final sy = cy + (y + 0.5 - tcy) * scale;
        final (r, g, b) = sampleClean(sx, sy);
        out.setPixelRgba(x, y, r, g, b, (alpha * 255).round());
      }
    }
    return out;
  }

  final mipmapSpecs = <String, (int, int)>{
    'mipmap-mdpi': (48, 108),
    'mipmap-hdpi': (72, 162),
    'mipmap-xhdpi': (96, 216),
    'mipmap-xxhdpi': (144, 324),
    'mipmap-xxxhdpi': (192, 432),
  };

  for (final entry in mipmapSpecs.entries) {
    final folder = 'android/app/src/main/res/${entry.key}';
    Directory(folder).createSync(recursive: true);
    final (launcherSize, fgSize) = entry.value;

    final squareImg = buildSquareIcon(launcherSize, roundedCorners: true);
    File('$folder/ic_launcher.png').writeAsBytesSync(img.encodePng(squareImg));

    final roundImg = buildRoundIcon(launcherSize);
    File('$folder/ic_launcher_round.png').writeAsBytesSync(img.encodePng(roundImg));

    final fgImg = buildAdaptiveForeground(fgSize);
    File('$folder/ic_launcher_foreground.png').writeAsBytesSync(img.encodePng(fgImg));
  }

  // Drawable foreground (432x432)
  final drawableFg = buildAdaptiveForeground(432);
  File('android/app/src/main/res/drawable/ic_launcher_foreground.png')
      .writeAsBytesSync(img.encodePng(drawableFg));

  // Web icons
  File('web/icons/Icon-192.png')
      .writeAsBytesSync(img.encodePng(buildSquareIcon(192, roundedCorners: false)));
  File('web/icons/Icon-512.png')
      .writeAsBytesSync(img.encodePng(buildSquareIcon(512, roundedCorners: false)));
  File('web/icons/Icon-maskable-192.png')
      .writeAsBytesSync(img.encodePng(buildAdaptiveForeground(192)));
  File('web/icons/Icon-maskable-512.png')
      .writeAsBytesSync(img.encodePng(buildAdaptiveForeground(512)));

  // iOS icons
  final iosSpecs = <String, int>{
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };
  const iosDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  if (Directory(iosDir).existsSync()) {
    for (final entry in iosSpecs.entries) {
      final icon = buildSquareIcon(entry.value, roundedCorners: false);
      File('$iosDir/${entry.key}').writeAsBytesSync(img.encodePng(icon));
    }
  }

  stdout.writeln('Successfully generated clean app icons!');
}
