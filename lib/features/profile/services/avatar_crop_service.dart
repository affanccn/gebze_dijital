import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class AvatarCropService {
  static final ImagePicker _picker = ImagePicker();

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

  static String? processAndCropImageBytes(Uint8List rawBytes) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return null;

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

      final resized = img.copyResize(
        squareCropped,
        width: 500,
        height: 500,
        interpolation: img.Interpolation.linear,
      );

      final compressedBytes = img.encodeJpg(resized, quality: 85);

      final base64String = base64Encode(compressedBytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (_) {
      return null;
    }
  }
}
