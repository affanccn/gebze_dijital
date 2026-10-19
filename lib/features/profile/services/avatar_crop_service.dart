import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class AvatarCropService {
  static final ImagePicker _picker = ImagePicker();

  /// Galeriden görsel seçer, istemci tarafında zorunlu 500x500 px kare kırpar ve sıkıştırır.
  static Future<String?> pickAndCropFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    return processAndCropImageBytes(bytes);
  }

  /// Kameradan fotoğraf çeker, istemci tarafında zorunlu 500x500 px kare kırpar ve sıkıştırır.
  static Future<String?> pickAndCropFromCamera() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    return processAndCropImageBytes(bytes);
  }

  /// İstemci tarafında 500x500 px kare kırpma (center-crop) ve JPEG sıkıştırma (quality 85)
  static String? processAndCropImageBytes(Uint8List rawBytes) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return null;

      // 1. Kare kırpma (Merkezden kare kesit alımı)
      final size = math.min(decoded.width, decoded.height);
      final x = (decoded.width - size) ~/ 2;
      final y = (decoded.height - size) ~/ 2;

      final squareCropped = img.copyCrop(
        decoded,
        x: x,
        y: y,
        width: size,
        height: size,
      );

      // 2. Tam 500x500 piksel boyutlandırma
      final resized = img.copyResize(
        squareCropped,
        width: 500,
        height: 500,
        interpolation: img.Interpolation.linear,
      );

      // 3. Kaliteli ve optimize JPEG sıkıştırma (Quality 85)
      final compressedBytes = img.encodeJpg(resized, quality: 85);

      // 4. Data URI olarak hazırla
      final base64String = base64Encode(compressedBytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (_) {
      return null;
    }
  }
}
