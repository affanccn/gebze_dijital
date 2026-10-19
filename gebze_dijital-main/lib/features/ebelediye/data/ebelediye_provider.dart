import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ebelediye_model.dart';

/// Fallback / Varsayılan Gebze Belediyesi E-Belediye Kategorileri
final List<EBelediyeCategory> kFallbackEBelediyeCategories = [
  const EBelediyeCategory(
    id: 29,
    name: 'Vergi İşlemleri',
    services: [
      EBelediyeService(
        id: 21,
        name: 'Vergi / Borç Ödeme',
        description: 'Emlak, çevre temizlik, ilan-reklam vergisi ve belediye borcu sorgulama/ödeme portalı',
        url: 'https://portal.gebze.bel.tr/ui/user/login',
        hasModal: false,
      ),
      EBelediyeService(
        id: 123,
        name: 'e-Beyan',
        description: 'Arsa, arazi, mesken, işyeri ve çevre temizlik e-beyan bildirim formları',
        url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/',
        hasModal: true,
        modalSteps: [
          EBelediyeModalStep(
            id: 'step1',
            title: 'Başvuru Türünüzü Seçiniz',
            options: [
              EBelediyeModalOption(
                text: 'Gerçek Kişi (Vatandaş)',
                nextStep: 'step2-88',
              ),
              EBelediyeModalOption(
                text: 'Tüzel Kişi (Şirket / Kurum)',
                nextStep: 'step2-89',
              ),
            ],
          ),
          EBelediyeModalStep(
            id: 'step2-88',
            title: 'Gerçek Kişi e-Beyan Bildirimleri',
            backStep: 'step1',
            options: [
              EBelediyeModalOption(
                text: 'Mesken e-Beyan Bildirimi',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-mesken-beyani-bildirim-formu/',
              ),
              EBelediyeModalOption(
                text: 'Arsa e-Beyan Bildirimi',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-arsa-beyani-bildirim-formu/',
              ),
              EBelediyeModalOption(
                text: 'Arazi e-Beyan Bildirimi',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-arazi-beyani-bildirim-formu/',
              ),
              EBelediyeModalOption(
                text: 'İşyeri e-Beyan Bildirimi',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-isyeri-beyani-bildirim-formu/',
              ),
              EBelediyeModalOption(
                text: 'Çevre Temizlik e-Beyan Bildirimi',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-cevre-ve-temizlik-beyani/',
              ),
              EBelediyeModalOption(
                text: 'İlan ve Reklam e-Beyan Bildirimi',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-ilan-ve-reklam-beyani/',
              ),
            ],
          ),
          EBelediyeModalStep(
            id: 'step2-89',
            title: 'Tüzel Kişi e-Beyan Bildirimleri',
            backStep: 'step1',
            options: [
              EBelediyeModalOption(
                text: 'Mesken e-Beyan Bildirimi (Tüzel)',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-mesken-beyani-bildirim-formu-tuzel/#/',
              ),
              EBelediyeModalOption(
                text: 'Arsa e-Beyan Bildirimi (Tüzel)',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-arsa-beyani-bildirim-formu-tuzel/#/',
              ),
              EBelediyeModalOption(
                text: 'İşyeri e-Beyan Bildirimi (Tüzel)',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-isyeri-beyani-bildirim-formu-tuzel/#/',
              ),
              EBelediyeModalOption(
                text: 'Çevre Temizlik Bildirimi (Tüzel)',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-cevre-ve-temizlik-beyani-tuzel/#/',
              ),
              EBelediyeModalOption(
                text: 'İlan ve Reklam Bildirimi (Tüzel)',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-ilan-ve-reklam-beyani-tuzel/#/',
              ),
            ],
          ),
        ],
      ),
      EBelediyeService(
        id: 60,
        name: 'e-Beyan Bildirim Takip',
        description: 'Daha önce yaptığınız e-beyan başvurularının onay ve inceleme durumunu takip edin',
        url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/#/Status',
        hasModal: false,
      ),
    ],
  ),
  const EBelediyeCategory(
    id: 30,
    name: 'Gebze İletişim Merkezi',
    services: [
      EBelediyeService(
        id: 124,
        name: 'Başvuru Formu',
        description: 'İstek, şikayet, teşekkür, proje önerisi ve ihbar bildirimlerinizi online iletin',
        url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/',
        hasModal: true,
        modalSteps: [
          EBelediyeModalStep(
            id: 'step1',
            title: 'Başvuru Türünüzü Seçiniz',
            options: [
              EBelediyeModalOption(
                text: 'İstek Bildirimi',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/?incident_type_id=1&hidden_fields=incident_type_id#/',
              ),
              EBelediyeModalOption(
                text: 'Şikayet Bildirimi',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/?incident_type_id=2&hidden_fields=incident_type_id#/',
              ),
              EBelediyeModalOption(
                text: 'Teşekkür Bildirimi',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/?incident_type_id=3&hidden_fields=incident_type_id#/',
              ),
              EBelediyeModalOption(
                text: 'Proje Önerisi Bildirimi',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/?incident_type_id=4&hidden_fields=incident_type_id#/',
              ),
              EBelediyeModalOption(
                text: 'Bilgi Talebi',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/?incident_type_id=5&hidden_fields=incident_type_id#/',
              ),
              EBelediyeModalOption(
                text: 'İhbar',
                url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/?incident_type_id=6&hidden_fields=incident_type_id#/',
              ),
            ],
          ),
        ],
      ),
      EBelediyeService(
        id: 69,
        name: 'Başvuru Takip',
        description: 'T.C. Kimlik No veya Başvuru Takip Numarası ile başvurunuzun sonucunu sorgulayın',
        url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/#/Status',
        hasModal: false,
      ),
      EBelediyeService(
        id: 125,
        name: 'Bilgi Edinme (CİMER)',
        description: 'Cumhurbaşkanlığı İletişim Merkezi (CİMER) üzerinden yasal bilgi edinme başvurusu',
        url: 'https://www.cimer.gov.tr/',
        hasModal: false,
      ),
    ],
  ),
  const EBelediyeCategory(
    id: 31,
    name: 'İnteraktif Hizmetler',
    services: [
      EBelediyeService(
        id: 45,
        name: 'e-Eksper',
        description: 'Gayrimenkul değerleme ve ekspertiz raporu belge başvuruları',
        url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/eeksper#/',
        hasModal: false,
      ),
      EBelediyeService(
        id: 51,
        name: 'e-İşyeri Ruhsat',
        description: 'Sıhhi ve gayrisıhhi müesseseler için online işyeri açma ruhsat başvurusu',
        url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-isyeri-ruhsat#/',
        hasModal: false,
      ),
      EBelediyeService(
        id: 47,
        name: 'e-Rayiç Belgesi',
        description: 'e-Devlet üzerinden emlak vergisi bildirim sureti ve rayiç bedel sorgulama',
        url: 'https://www.turkiye.gov.tr/gebze-belediyesi-emlak-vergisi-bildirim-sureti-sorgu',
        hasModal: false,
      ),
      EBelediyeService(
        id: 59,
        name: 'E-Moloz Hattı',
        description: 'Ev ve işyerinizdeki inşaat ve tadilat atıkları için belediye moloz alım talebi',
        url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-moloz-hatti#/',
        hasModal: false,
      ),
      EBelediyeService(
        id: 116,
        name: 'e-Geri Dönüşüm',
        description: 'Geri dönüştürülebilir atıklar, tekstil ve elektronik atık toplama talebi',
        url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/e-geridonusum-hatti#/',
        hasModal: false,
      ),
      EBelediyeService(
        id: 81,
        name: 'Sosyal Yardım Başvurusu',
        description: 'İhtiyaç sahibi aileler için belediyemiz sosyal destek ve yardım başvurusu',
        url: 'https://ulakbel.gebze.bel.tr/WebBasvuru/sosyal-yardimlar-online-basvuru-formu#/',
        hasModal: false,
      ),
    ],
  ),
  const EBelediyeCategory(
    id: 32,
    name: 'İmar Yönetim Sistemi',
    services: [
      EBelediyeService(
        id: 127,
        name: 'İmar Durumu Başvurusu',
        description: 'İnşaat veya tevhit-ifraz amaçlı resmi parsel imar durumu belgesi başvurusu',
        url: 'https://eimar.gebze.bel.tr/YapiBelgeleriWeb/BasvuruTurList/RedirectEDevlet?BasvuruTurId=0K3%2Ad2JOcWBtkopYTDZSfA%3D%3D',
        hasModal: false,
      ),
      EBelediyeService(
        id: 128,
        name: 'Yapı Ruhsatı Başvuruları',
        description: 'Mimari, statik, mekanik ve elektrik proje onay ve yapı ruhsatı süreçleri',
        url: 'https://eimar.gebze.bel.tr/',
        hasModal: false,
      ),
    ],
  ),
  const EBelediyeCategory(
    id: 17,
    name: 'Spor ve Eğitim',
    services: [
      EBelediyeService(
        id: 130,
        name: 'SENDE (Kayıt ve Eğitim Portalı)',
        description: 'GESMEK, spor okulları, kış okulları ve çocuk atölyeleri online kayıt sistemi',
        url: 'https://sende.gebze.bel.tr/',
        hasModal: false,
      ),
    ],
  ),
];

/// E-Belediye Kategorileri Provider (Firestore 'ebelediye_categories' veya JSON fallback)
final eBelediyeCategoriesProvider = FutureProvider.autoDispose<List<EBelediyeCategory>>((ref) async {
  try {
    // 1. Önce Firestore'dan kontrol et (Admin panelinden güncellenmişse oradan gelir)
    final snapshot = await FirebaseFirestore.instance
        .collection('ebelediye_categories')
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.map((doc) => EBelediyeCategory.fromMap(doc.data())).toList();
    }
  } catch (_) {
    // Firestore hatası durumunda devam et
  }

  // 2. Canlı web servisinden çekmeyi dene (dart:io HttpClient)
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);
    final request = await client.getUrl(Uri.parse('https://www.gebze.bel.tr/json/ebelediye.json'));
    final response = await request.close().timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final catList = decoded['categories'] as List<dynamic>?;
      if (catList != null && catList.isNotEmpty) {
        return catList.map((c) => EBelediyeCategory.fromMap(c as Map<String, dynamic>)).toList();
      }
    }
    client.close();
  } catch (_) {
    // Offline veya zaman aşımı durumunda fallback verisi döner
  }

  // 3. Fallback hazır liste
  return kFallbackEBelediyeCategories;
});
