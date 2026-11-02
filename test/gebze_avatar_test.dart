import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:gebze_dijital/features/profile/models/gebze_avatar.dart';
import 'package:gebze_dijital/features/profile/services/avatar_crop_service.dart';
import 'package:gebze_dijital/features/profile/widgets/gebze_avatar_picker_dialog.dart';

void main() {
  group('Gebze Avatar Models & Providers', () {
    test('kGebzeAvatars contains 15 visual-only avatars with Genel and Özel categories', () {
      expect(kGebzeAvatars.length, equals(15));

      final ids = <String>{};
      for (int i = 0; i < kGebzeAvatars.length; i++) {
        final a = kGebzeAvatars[i];
        expect(a.id, isNotEmpty);
        expect(ids.contains(a.id), isFalse, reason: 'Duplicate ID: ${a.id}');
        ids.add(a.id);

        expect(a.assetPath, startsWith('assets/images/avatars/avatar_'));
        expect(a.assetPath, endsWith('.png'));
        expect(a.titleTr, isEmpty);

        if (i < 12) {
          expect(a.category, equals('Genel'));
        } else {
          expect(a.category, equals('Özel'));
        }
      }
    });

    test('getAvatarImageProvider resolves asset, memory and network URLs', () {
      // Null or empty
      expect(getAvatarImageProvider(null), isNull);
      expect(getAvatarImageProvider(''), isNull);
      expect(getAvatarImageProvider('   '), isNull);

      // Asset
      final assetProvider = getAvatarImageProvider('assets/images/avatars/avatar_1.png');
      expect(assetProvider, isA<AssetImage>());
      expect((assetProvider as AssetImage).assetName, equals('assets/images/avatars/avatar_1.png'));

      // Network
      final netProvider = getAvatarImageProvider('https://example.com/avatar.jpg');
      expect(netProvider, isA<NetworkImage>());

      // Base64 Data URI
      final sampleImg = img.Image(width: 10, height: 10);
      final jpgBytes = img.encodeJpg(sampleImg);
      final b64 = 'data:image/jpeg;base64,${base64Encode(jpgBytes)}';
      final memProvider = getAvatarImageProvider(b64);
      expect(memProvider, isA<MemoryImage>());
    });
  });

  group('AvatarCropService 500x500 Strict Crop Logic', () {
    test('Non-square image is cropped to 1:1 and resized to exactly 500x500', () {
      // Create an 800x400 non-square image
      final rawImage = img.Image(width: 800, height: 400);
      img.fill(rawImage, color: img.ColorRgb8(255, 100, 50));
      final rawBytes = Uint8List.fromList(img.encodePng(rawImage));

      // Process via crop and compress
      final dataUri = AvatarCropService.processAndCropImageBytes(rawBytes);
      expect(dataUri, isNotNull);
      expect(dataUri, startsWith('data:image/jpeg;base64,'));

      // Decode the output back and verify strict 500x500 size
      final pureB64 = dataUri!.substring('data:image/jpeg;base64,'.length);
      final decodedBytes = base64Decode(pureB64);
      final finalImage = img.decodeJpg(decodedBytes);

      expect(finalImage, isNotNull);
      expect(finalImage!.width, equals(500));
      expect(finalImage.height, equals(500));
    });

    test('Tall portrait image is cropped to 1:1 and resized to exactly 500x500', () {
      // Create a 600x1200 portrait image
      final rawImage = img.Image(width: 600, height: 1200);
      img.fill(rawImage, color: img.ColorRgb8(10, 50, 200));
      final rawBytes = Uint8List.fromList(img.encodePng(rawImage));

      final dataUri = AvatarCropService.processAndCropImageBytes(rawBytes);
      expect(dataUri, isNotNull);

      final pureB64 = dataUri!.substring('data:image/jpeg;base64,'.length);
      final decodedBytes = base64Decode(pureB64);
      final finalImage = img.decodeJpg(decodedBytes);

      expect(finalImage, isNotNull);
      expect(finalImage!.width, equals(500));
      expect(finalImage.height, equals(500));
    });
  });

  group('GebzeAvatarPickerSheet Widget Test', () {
    testWidgets('renders clean avatar picker modal and allows selection', (tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  GebzeAvatarPickerSheet.show(
                    ctx,
                    currentAvatarUrl: kGebzeAvatars.first.assetPath,
                    onAvatarSelected: (url) {
                      selected = url;
                    },
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify UI elements
      expect(find.text('Profil Fotoğrafı Seçin'), findsOneWidget);
      expect(find.text('Galeriden Seç'), findsOneWidget);
      expect(find.text('Kamera'), findsOneWidget);
      expect(find.text('Fotoğrafı Kaydet'), findsOneWidget);

      // Tap Save button
      await tester.tap(find.text('Fotoğrafı Kaydet'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
    });
  });
}
