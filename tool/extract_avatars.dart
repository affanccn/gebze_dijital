import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  final file = File(r'C:\Users\Asus\.gemini\antigravity-ide\brain\6f650fea-ceaf-4615-9c9a-4de9b755e2f4\.user_uploaded\media_1792394091939.jpg');
  final bytes = file.readAsBytesSync();
  final image = img.decodeImage(bytes)!;

  final colCenters = [104, 308, 512, 715, 919];
  final rowCenters = [126, 344, 563];
  const cropSize = 206;
  const halfSize = cropSize ~/ 2;
  const targetSize = 500;

  final outputDir = Directory('assets/images/avatars');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  int avatarIndex = 1;

  for (int r = 0; r < 3; r++) {
    for (int c = 0; c < 5; c++) {
      final cx = colCenters[c];
      final cy = rowCenters[r];

      int x1 = cx - halfSize;
      int y1 = cy - halfSize;
      if (x1 < 0) x1 = 0;
      if (y1 < 0) y1 = 0;
      if (x1 + cropSize > image.width) x1 = image.width - cropSize;
      if (y1 + cropSize > image.height) y1 = image.height - cropSize;

      // 1. Crop original patch
      final patch = img.copyCrop(image, x: x1, y: y1, width: cropSize, height: cropSize);

      // 2. High quality cubic resize to 500x500 FIRST
      final resizedRgb = img.copyResize(
        patch,
        width: targetSize,
        height: targetSize,
        interpolation: img.Interpolation.cubic,
      );

      // 3. Convert to 4-channel RGBA image
      final rgbaImage = img.Image(width: targetSize, height: targetSize, numChannels: 4);
      for (int y = 0; y < targetSize; y++) {
        for (int x = 0; x < targetSize; x++) {
          final p = resizedRgb.getPixel(x, y);
          rgbaImage.setPixelRgba(x, y, p.r, p.g, p.b, 255);
        }
      }

      // 4. Flood fill white background directly at 500x500 resolution
      final visited = List.generate(targetSize, (_) => List.filled(targetSize, false));
      final queue = Queue<Point>();

      bool isBackground(int px, int py) {
        final p = rgbaImage.getPixel(px, py);
        final isBright = p.r > 235 && p.g > 235 && p.b > 235;
        final isNeutral = (p.r - p.g).abs() < 20 && (p.r - p.b).abs() < 20;
        return isBright && isNeutral;
      }

      void addSeed(int sx, int sy) {
        if (isBackground(sx, sy) && !visited[sy][sx]) {
          visited[sy][sx] = true;
          queue.add(Point(sx, sy));
        }
      }

      for (int x = 0; x < targetSize; x++) {
        addSeed(x, 0);
        addSeed(x, targetSize - 1);
      }
      for (int y = 0; y < targetSize; y++) {
        addSeed(0, y);
        addSeed(targetSize - 1, y);
      }

      final bgMask = List.generate(targetSize, (_) => List.filled(targetSize, false));

      while (queue.isNotEmpty) {
        final pt = queue.removeFirst();
        bgMask[pt.y][pt.x] = true;

        const dx = [-1, 1, 0, 0];
        const dy = [0, 0, -1, 1];

        for (int i = 0; i < 4; i++) {
          final nx = pt.x + dx[i];
          final ny = pt.y + dy[i];

          if (nx >= 0 && nx < targetSize && ny >= 0 && ny < targetSize) {
            if (!visited[ny][nx] && isBackground(nx, ny)) {
              visited[ny][nx] = true;
              queue.add(Point(nx, ny));
            }
          }
        }
      }

      // Apply transparency and smooth 2-pixel anti-aliasing edge
      for (int y = 0; y < targetSize; y++) {
        for (int x = 0; x < targetSize; x++) {
          if (bgMask[y][x]) {
            rgbaImage.setPixelRgba(x, y, 0, 0, 0, 0);
          } else {
            // Check distance to background for soft anti-aliased edge
            int bgNeighbors = 0;
            for (int dy = -2; dy <= 2; dy++) {
              for (int dx = -2; dx <= 2; dx++) {
                final nx = x + dx;
                final ny = y + dy;
                if (nx >= 0 && nx < targetSize && ny >= 0 && ny < targetSize) {
                  if (bgMask[ny][nx]) bgNeighbors++;
                }
              }
            }
            if (bgNeighbors > 0) {
              final p = rgbaImage.getPixel(x, y);
              // If near white, feather alpha
              final whiteness = (p.r + p.g + p.b) / (3 * 255.0);
              if (whiteness > 0.88) {
                final alpha = ((1.0 - (bgNeighbors / 25.0)) * 255).clamp(0, 255).round();
                rgbaImage.setPixelRgba(x, y, p.r, p.g, p.b, alpha);
              }
            }
          }
        }
      }

      final outPath = 'assets/images/avatars/avatar_$avatarIndex.png';
      File(outPath).writeAsBytesSync(img.encodePng(rgbaImage));
      print('Saved $outPath at high-res 500x500');
      avatarIndex++;
    }
  }
}

class Point {
  final int x;
  final int y;
  Point(this.x, this.y);
}
