// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Generate 15 Profile Avatars', () async {
    final avatarSpecs = [
      // 4: Erkek Genç
      _AvatarSpec(
        id: 4,
        bgColor: const Color(0xFFF59E0B), // Amber orange
        skinColor: const Color(0xFFFFDFC4),
        hairColor: const Color(0xFF2C1810), // Dark brown
        clothesColor: const Color(0xFF1E293B), // Slate dark
        type: _AvatarType.maleYoung,
      ),
      // 5: Kız Genç
      _AvatarSpec(
        id: 5,
        bgColor: const Color(0xFF0284C7), // Sky blue
        skinColor: const Color(0xFFFFE0BD),
        hairColor: const Color(0xFF4A2810), // Chestnut
        clothesColor: const Color(0xFF7C3AED), // Purple
        type: _AvatarType.femaleYoung,
      ),
      // 6: Kız Genç Türbanlı
      _AvatarSpec(
        id: 6,
        bgColor: const Color(0xFFE11D48), // Rose red
        skinColor: const Color(0xFFFFDFC4),
        hairColor: Colors.transparent,
        clothesColor: const Color(0xFF0F766E), // Teal
        hijabColor: const Color(0xFFF1F5F9), // Soft white/cream
        type: _AvatarType.femaleYoungHijab,
      ),
      // 7: Erkek Çalışan / Mühendis
      _AvatarSpec(
        id: 7,
        bgColor: const Color(0xFF0A2A66), // Gebze Navy
        skinColor: const Color(0xFFFBD3BD),
        hairColor: const Color(0xFF1F2937),
        clothesColor: const Color(0xFF3B82F6), // Tech blue
        hasGlasses: true,
        type: _AvatarType.maleWorker,
      ),
      // 8: Kadın Çalışan / Yönetici
      _AvatarSpec(
        id: 8,
        bgColor: const Color(0xFFEA580C), // Orange
        skinColor: const Color(0xFFFFDFC4),
        hairColor: const Color(0xFF1E1B18), // Black
        clothesColor: const Color(0xFF0F172A), // Dark suit
        type: _AvatarType.femaleWorker,
      ),
      // 9: Kadın Çalışan Türbanlı
      _AvatarSpec(
        id: 9,
        bgColor: const Color(0xFF0A2A66), // Gebze Navy
        skinColor: const Color(0xFFFFDFC4),
        hairColor: Colors.transparent,
        clothesColor: const Color(0xFF334155), // Corporate blazer
        hijabColor: const Color(0xFFE2E8F0), // Pearl silver
        type: _AvatarType.femaleWorkerHijab,
      ),
      // 10: Erkek Yaşlı (Gebzeli Dede)
      _AvatarSpec(
        id: 10,
        bgColor: const Color(0xFF059669), // Emerald green
        skinColor: const Color(0xFFF5CEB3),
        hairColor: const Color(0xFFE2E8F0), // Silver gray
        clothesColor: const Color(0xFF78350F), // Warm cardigan
        hasGlasses: true,
        type: _AvatarType.maleElderly,
      ),
      // 11: Kadın Yaşlı (Gebzeli Teyze)
      _AvatarSpec(
        id: 11,
        bgColor: const Color(0xFF7C3AED), // Violet
        skinColor: const Color(0xFFF8D7BE),
        hairColor: const Color(0xFFCBD5E1), // Gray bob
        clothesColor: const Color(0xFFBE185D), // Magenta cardigan
        type: _AvatarType.femaleElderly,
      ),
      // 12: Kadın Yaşlı Türbanlı (Tonton Nine)
      _AvatarSpec(
        id: 12,
        bgColor: const Color(0xFFD97706), // Warm amber
        skinColor: const Color(0xFFF8D7BE),
        hairColor: Colors.transparent,
        clothesColor: const Color(0xFF047857), // Forest green
        hijabColor: const Color(0xFFFFFFFF), // Pure white traditional
        type: _AvatarType.femaleElderlyHijab,
      ),
      // 13: Gebzespor Taraftarı Genç
      _AvatarSpec(
        id: 13,
        bgColor: const Color(0xFF581C87), // Gebzespor Moru
        skinColor: const Color(0xFFFFDFC4),
        hairColor: const Color(0xFF18181B),
        clothesColor: const Color(0xFFFFFFFF), // White with purple scarf
        type: _AvatarType.gebzesporFan,
      ),
      // 14: Doğa & Pati Gönüllüsü
      _AvatarSpec(
        id: 14,
        bgColor: const Color(0xFF10B981), // Emerald
        skinColor: const Color(0xFFFFE0BD),
        hairColor: const Color(0xFF78350F),
        clothesColor: const Color(0xFF047857),
        type: _AvatarType.patiVolunteer,
      ),
      // 15: Gebze Dijital Hemşehri
      _AvatarSpec(
        id: 15,
        bgColor: const Color(0xFFFF7A00), // Gebze Turuncusu
        skinColor: const Color(0xFFFFDFC4),
        hairColor: const Color(0xFF0F172A),
        clothesColor: const Color(0xFF0A2A66),
        type: _AvatarType.digitalCitizen,
      ),
    ];

    final outDir = Directory('assets/images/avatars');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    for (final spec in avatarSpecs) {
      final img = await _renderAvatar(spec);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final file = File('assets/images/avatars/avatar_${spec.id}.png');
      file.writeAsBytesSync(byteData!.buffer.asUint8List());
      // ignore: avoid_print
      print('Rendered avatar_${spec.id}.png (${file.lengthSync()} bytes)');
    }
  });
}

enum _AvatarType {
  maleYoung,
  femaleYoung,
  femaleYoungHijab,
  maleWorker,
  femaleWorker,
  femaleWorkerHijab,
  maleElderly,
  femaleElderly,
  femaleElderlyHijab,
  gebzesporFan,
  patiVolunteer,
  digitalCitizen,
}

class _AvatarSpec {
  final int id;
  final Color bgColor;
  final Color skinColor;
  final Color hairColor;
  final Color clothesColor;
  final Color? hijabColor;
  final bool hasGlasses;
  final _AvatarType type;

  _AvatarSpec({
    required this.id,
    required this.bgColor,
    required this.skinColor,
    required this.hairColor,
    required this.clothesColor,
    this.hijabColor,
    this.hasGlasses = false,
    required this.type,
  });
}

Future<ui.Image> _renderAvatar(_AvatarSpec spec) async {
  const size = 500.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

  const center = Offset(250, 250);
  const radius = 220.0;

  // Background Circle
  final bgPaint = Paint()
    ..isAntiAlias = true
    ..color = spec.bgColor
    ..style = PaintingStyle.fill;
  canvas.drawCircle(center, radius, bgPaint);

  // Clip character inside the circle
  canvas.save();
  final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  canvas.clipPath(clipPath);

  // Paint helpers
  final skinPaint = Paint()
    ..isAntiAlias = true
    ..color = spec.skinColor
    ..style = PaintingStyle.fill;

  final shadowSkinPaint = Paint()
    ..isAntiAlias = true
    ..color = spec.skinColor.withRed((spec.skinColor.red * 0.88).round())
    ..style = PaintingStyle.fill;

  final clothesPaint = Paint()
    ..isAntiAlias = true
    ..color = spec.clothesColor
    ..style = PaintingStyle.fill;

  final hairPaint = Paint()
    ..isAntiAlias = true
    ..color = spec.hairColor
    ..style = PaintingStyle.fill;

  final eyePaint = Paint()
    ..isAntiAlias = true
    ..color = const Color(0xFF1E293B)
    ..style = PaintingStyle.fill;

  final linePaint = Paint()
    ..isAntiAlias = true
    ..color = const Color(0xFF78350F).withAlpha(120)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;

  // 1. Shoulders & Body
  final bodyPath = Path();
  bodyPath.moveTo(60, 500);
  bodyPath.quadraticBezierTo(90, 340, 180, 320);
  bodyPath.lineTo(320, 320);
  bodyPath.quadraticBezierTo(410, 340, 440, 500);
  bodyPath.close();
  canvas.drawPath(bodyPath, clothesPaint);

  // Collar / Inner shirt
  final collarPath = Path();
  collarPath.moveTo(210, 320);
  collarPath.lineTo(250, 375);
  collarPath.lineTo(290, 320);
  collarPath.close();
  canvas.drawPath(collarPath, Paint()..color = Colors.white);

  // 2. Neck
  final neckRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(218, 220, 64, 110),
    const Radius.circular(20),
  );
  canvas.drawRRect(neckRect, skinPaint);

  // Neck shadow under chin
  final neckShadow = Path();
  neckShadow.moveTo(218, 240);
  neckShadow.quadraticBezierTo(250, 275, 282, 240);
  neckShadow.lineTo(282, 260);
  neckShadow.quadraticBezierTo(250, 295, 218, 260);
  neckShadow.close();
  canvas.drawPath(neckShadow, shadowSkinPaint);

  // 3. Head & Face
  final headRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(175, 120, 150, 175),
    const Radius.circular(75),
  );
  canvas.drawRRect(headRect, skinPaint);

  // Ears
  canvas.drawCircle(const Offset(172, 205), 16, skinPaint);
  canvas.drawCircle(const Offset(328, 205), 16, skinPaint);
  canvas.drawCircle(const Offset(172, 205), 9, shadowSkinPaint);
  canvas.drawCircle(const Offset(328, 205), 9, shadowSkinPaint);

  // 4. Hair or Hijab
  final isHijab = spec.type == _AvatarType.femaleYoungHijab ||
      spec.type == _AvatarType.femaleWorkerHijab ||
      spec.type == _AvatarType.femaleElderlyHijab;

  if (isHijab) {
    final hColor = spec.hijabColor ?? const Color(0xFFF1F5F9);
    final hijabPaint = Paint()
      ..isAntiAlias = true
      ..color = hColor
      ..style = PaintingStyle.fill;

    final hijabShadowPaint = Paint()
      ..isAntiAlias = true
      ..color = hColor.withRed((hColor.red * 0.88).round())
      ..style = PaintingStyle.fill;

    // Head wrap
    final wrapPath = Path();
    wrapPath.moveTo(140, 240);
    wrapPath.quadraticBezierTo(145, 90, 250, 90);
    wrapPath.quadraticBezierTo(355, 90, 360, 240);
    wrapPath.quadraticBezierTo(360, 360, 250, 370);
    wrapPath.quadraticBezierTo(140, 360, 140, 240);
    wrapPath.close();
    canvas.drawPath(wrapPath, hijabPaint);

    // Face cutout inside hijab
    final faceOval = Path();
    faceOval.addOval(const Rect.fromLTWH(180, 125, 140, 155));
    canvas.drawPath(faceOval, skinPaint);

    // Hijab lower folds over shoulders
    final drapePath = Path();
    drapePath.moveTo(170, 280);
    drapePath.quadraticBezierTo(250, 395, 330, 280);
    drapePath.lineTo(350, 360);
    drapePath.quadraticBezierTo(250, 430, 150, 360);
    drapePath.close();
    canvas.drawPath(drapePath, hijabShadowPaint);
  } else {
    // Regular Hair
    if (spec.type == _AvatarType.femaleYoung || spec.type == _AvatarType.femaleWorker) {
      // Long stylish female hair
      final hairBack = Path();
      hairBack.moveTo(160, 200);
      hairBack.quadraticBezierTo(140, 310, 150, 380);
      hairBack.lineTo(350, 380);
      hairBack.quadraticBezierTo(360, 310, 340, 200);
      hairBack.close();
      canvas.drawPath(hairBack, hairPaint);

      final hairTop = Path();
      hairTop.moveTo(165, 200);
      hairTop.quadraticBezierTo(170, 95, 250, 95);
      hairTop.quadraticBezierTo(330, 95, 335, 200);
      hairTop.quadraticBezierTo(290, 145, 250, 145);
      hairTop.quadraticBezierTo(210, 145, 165, 200);
      hairTop.close();
      canvas.drawPath(hairTop, hairPaint);
    } else if (spec.type == _AvatarType.femaleElderly) {
      // Curly silver hair
      final hairPath = Path();
      hairPath.addOval(const Rect.fromLTWH(155, 100, 190, 140));
      canvas.drawPath(hairPath, hairPaint);
      canvas.drawCircle(const Offset(165, 170), 30, hairPaint);
      canvas.drawCircle(const Offset(335, 170), 30, hairPaint);
      canvas.drawCircle(const Offset(250, 100), 35, hairPaint);
    } else {
      // Male modern haircut
      final hairTop = Path();
      hairTop.moveTo(168, 175);
      hairTop.quadraticBezierTo(170, 95, 250, 95);
      hairTop.quadraticBezierTo(330, 95, 332, 175);
      hairTop.quadraticBezierTo(310, 140, 250, 138);
      hairTop.quadraticBezierTo(190, 140, 168, 175);
      hairTop.close();
      canvas.drawPath(hairTop, hairPaint);

      // Sideburns
      canvas.drawRect(const Rect.fromLTWH(172, 170, 10, 25), hairPaint);
      canvas.drawRect(const Rect.fromLTWH(318, 170, 10, 25), hairPaint);
    }
  }

  // 5. Eyes, Brows, Nose, Smile
  // Eyebrows
  final browPaint = Paint()
    ..isAntiAlias = true
    ..color = isHijab ? const Color(0xFF2C1810) : spec.hairColor
    ..strokeWidth = 3.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final leftBrow = Path()
    ..moveTo(205, 185)
    ..quadraticBezierTo(220, 180, 235, 185);
  final rightBrow = Path()
    ..moveTo(265, 185)
    ..quadraticBezierTo(280, 180, 295, 185);
  canvas.drawPath(leftBrow, browPaint);
  canvas.drawPath(rightBrow, browPaint);

  // Eyes
  canvas.drawOval(const Rect.fromLTWH(212, 195, 12, 16), eyePaint);
  canvas.drawOval(const Rect.fromLTWH(276, 195, 12, 16), eyePaint);
  // Highlights
  canvas.drawCircle(const Offset(216, 199), 3, Paint()..color = Colors.white);
  canvas.drawCircle(const Offset(280, 199), 3, Paint()..color = Colors.white);

  // Nose
  final nosePath = Path()
    ..moveTo(250, 205)
    ..quadraticBezierTo(256, 225, 248, 228);
  canvas.drawPath(nosePath, linePaint);

  // Smile
  final smilePath = Path()
    ..moveTo(230, 245)
    ..quadraticBezierTo(250, 262, 270, 245);
  canvas.drawPath(
    smilePath,
    Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFFBE185D)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round,
  );

  // 6. Special Accessories:
  if (spec.hasGlasses) {
    final glassPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(220, 202), 22, glassPaint);
    canvas.drawCircle(const Offset(280, 202), 22, glassPaint);
    canvas.drawLine(const Offset(242, 202), const Offset(258, 202), glassPaint);
  }

  // Gebzespor Scarf
  if (spec.type == _AvatarType.gebzesporFan) {
    final scarfPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF581C87)
      ..style = PaintingStyle.fill;
    final scarfRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(180, 295, 140, 45),
      const Radius.circular(16),
    );
    canvas.drawRRect(scarfRect, scarfPaint);
    // White stripes
    final stripePaint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(210, 295, 15, 45), stripePaint);
    canvas.drawRect(const Rect.fromLTWH(275, 295, 15, 45), stripePaint);
  }

  // Pati Badge
  if (spec.type == _AvatarType.patiVolunteer) {
    final badgePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(215, 370), 16, badgePaint);
    final pawPaint = Paint()..color = const Color(0xFF047857);
    canvas.drawCircle(const Offset(215, 372), 6, pawPaint);
    canvas.drawCircle(const Offset(210, 364), 3, pawPaint);
    canvas.drawCircle(const Offset(215, 362), 3, pawPaint);
    canvas.drawCircle(const Offset(220, 364), 3, pawPaint);
  }

  // Digital Citizen Pin
  if (spec.type == _AvatarType.digitalCitizen) {
    final pinPaint = Paint()..color = const Color(0xFFFF7A00);
    canvas.drawCircle(const Offset(290, 370), 14, pinPaint);
    final starPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(290, 370), 5, starPaint);
  }

  canvas.restore();

  final picture = recorder.endRecording();
  return picture.toImage(size.toInt(), size.toInt());
}
