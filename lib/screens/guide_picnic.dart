import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Gebze Belediyesi - "Doğa & Piknik" (köydeki piknik, doğa ve mesire alanları)
/// Dosya yolu: lib/screens/guide_picnic.dart
///
/// Veri: Firestore `guide_picnic` koleksiyonu. Koleksiyon boşsa aşağıdaki
/// yedek liste (_fallbackPicnic) gösterilir.
///
/// Firestore alanları (hepsi opsiyonel, `name` hariç):
///   name, name_en, name_ar          -> String
///   summary, summary_en, summary_ar -> String
///   type                            -> 'piknik' | 'mesire' | 'doga' | 'park'
///   village                         -> köy / mahalle adı
///   address                         -> String
///   lat, lng                        -> number (varsa yol tarifi bunu kullanır)
///   mapQuery                        -> koordinat yoksa haritada aranacak metin
///   image                           -> https://... ya da gorsel/... asset yolu
///   features, features_en, features_ar -> `List<String>` (ör. çardak, otopark)
///   order                           -> number (sıralama)

class _C {
  static const navy = Color(0xFF0A2A66);
  static const orange = Color(0xFFFF7A00);
  static const line = Color(0xFFE4E9F2);
  static const field = Color(0xFFEEF2FA);
  static const textDark = Color(0xFF0A1F44);
  static const textMuted = Color(0xFF5F6F8A);
  static const green = Color(0xFF2E7D32);
}

String _t(String lang, String tr, String en, String ar) =>
    lang == 'en' ? en : (lang == 'ar' ? ar : tr);

String _norm(String p) => p.trim().replaceAll('\\', '/');

// ───────────────────────── Tür yardımcıları ─────────────────────────

const _types = ['piknik', 'mesire', 'doga', 'park'];

String _typeLabel(String type, String lang) {
  switch (type) {
    case 'piknik':
      return _t(lang, 'Piknik Alanı', 'Picnic Area', 'منطقة نزهة');
    case 'mesire':
      return _t(lang, 'Mesire Alanı', 'Recreation Area', 'منتزه ترفيهي');
    case 'doga':
      return _t(lang, 'Doğa Alanı', 'Nature Area', 'منطقة طبيعية');
    case 'park':
      return _t(lang, 'Park', 'Park', 'حديقة');
    default:
      return _t(lang, 'Tümü', 'All', 'الكل');
  }
}

/// Filtre çiplerinde kullanılan kısa etiketler (hepsi tek satıra sığsın diye).
String _typeChipLabel(String type, String lang) {
  switch (type) {
    case 'piknik':
      return _t(lang, 'Piknik', 'Picnic', 'نزهة');
    case 'mesire':
      return _t(lang, 'Mesire', 'Recreation', 'ترفيه');
    case 'doga':
      return _t(lang, 'Doğa', 'Nature', 'طبيعة');
    case 'park':
      return _t(lang, 'Park', 'Park', 'حديقة');
    default:
      return _t(lang, 'Tümü', 'All', 'الكل');
  }
}

IconData _typeIcon(String type) {
  switch (type) {
    case 'piknik':
      return Icons.deck_rounded;
    case 'mesire':
      return Icons.forest_rounded;
    case 'doga':
      return Icons.landscape_rounded;
    case 'park':
      return Icons.park_rounded;
    default:
      return Icons.nature_people_rounded;
  }
}

// ───────────────────────── Model ─────────────────────────

class GebzePicnic {
  final String id;
  final Map<String, dynamic> _m;
  final int order;

  GebzePicnic(this.id, this._m, {int? fallbackOrder})
      : order = (_m['order'] as num?)?.toInt() ?? fallbackOrder ?? 999;

  String text(String key, String lang) {
    if (lang == 'en' || lang == 'ar') {
      final v = (_m['${key}_$lang'] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return (_m[key] ?? '').toString().trim();
  }

  List<String> list(String key, String lang) {
    dynamic raw = _m['${key}_$lang'];
    if (raw is! List || raw.isEmpty) raw = _m[key];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String get type {
    final t = (_m['type'] ?? '').toString().trim().toLowerCase();
    return _types.contains(t) ? t : 'piknik';
  }

  String get image => (_m['image'] ?? '').toString();
  double? get lat => double.tryParse('${_m['lat'] ?? ''}');
  double? get lng => double.tryParse('${_m['lng'] ?? ''}');
  String get mapQuery => (_m['mapQuery'] ?? '').toString().trim();

  String get directionsUrl {
    final la = lat, ln = lng;
    final String dest;
    if (la != null && ln != null) {
      dest = '$la,$ln';
    } else {
      final q = mapQuery.isNotEmpty
          ? mapQuery
          : '${text('name', 'tr')} ${text('address', 'tr')} Gebze Kocaeli';
      dest = Uri.encodeComponent(q.trim());
    }
    return 'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving';
  }
}

// ───────────────────────── Yedek veri ─────────────────────────
// Firestore boşken görünür. Görsel/koordinat/açıklamayı Firestore'dan ekleyin.

List<GebzePicnic> _fallbackPicnic() {
  final items = <Map<String, dynamic>>[
    {
      'id': 'doga_beylikdagi',
      'name': 'Beylikdağı Orman Yürüyüşü',
      'name_en': 'Beylikdagi Forest Walk',
      'name_ar': 'مسار غابة بيليك داغي',
      'summary':
          'Gebze\'nin doğal yeşil alanlarından biri olan Beylikdağı Kent Ormanı, şehir hayatının yoğunluğundan uzaklaşmak ve doğayla vakit geçirmek isteyenler için değerlendirilebilecek bir alandır. Ağaçlandırılmış yamaçları ve orman dokusuyla açık havada yürüyüş yapmak, temiz hava almak ve doğa fotoğrafları çekmek isteyenlere farklı bir deneyim sunar.\n\nKent ormanı, Gebze\'nin yeşil alanlarını keşfetmek ve doğayla iç içe zaman geçirmek isteyen vatandaşlar için potansiyel bir doğa rotasıdır.\n\nZiyaret öncesi: Yürüyüş güzergâhı, erişim durumu ve mevcut olanaklar hakkında güncel bilgi alınması önerilir.',
      'summary_en':
          'One of Gebze\'s natural green areas, Beylikdagi City Forest offers a peaceful route for open-air walking, fresh air, and nature photography among afforested hillsides.\n\nPre-visit note: Checking the current route accessibility is recommended.',
      'summary_ar':
          'تعتبر غابة بيليك داغي الحضرية إحدى المناطق الخضراء الطبيعية في جبزة، وتوفر مساراً رائعاً للمشي في الهواء الطلق واستنشاق الهواء النقي والتصوير الطبيعي.',
      'type': 'doga',
      'village': 'Beylikdağı',
      'address': 'Beylikdağı, Gebze, Kocaeli',
      'mapQuery': 'Beylikdağı Kent Ormanı Gebze Kocaeli',
      'image': 'gorsel/piknik/beylikdagi.jpg',
      'features': ['Doğa Yürüyüşü', 'Manzara İzleme', 'Doğa Fotoğrafçılığı'],
      'features_en': ['Nature Walk', 'Scenic Views', 'Photography'],
      'features_ar': ['مشي في الطبيعة', 'إطلالات طبيعية', 'تصوير'],
      'order': 1,
    },
    {
      'id': 'doga_denizli_goleti',
      'name': 'Denizli Göleti Doğa Rotası',
      'name_en': 'Denizli Pond Nature Route',
      'name_ar': 'مسار بركة دينيزلي الطبيعي',
      'summary':
          'Gebze\'nin Denizli Mahallesi çevresinde yer alan Denizli Göleti, gölet manzarasını kırsal doğayla buluşturan bir yürüyüş noktasıdır. Gölet çevresindeki doğal alanlardan başlayan yürüyüşler, toprak yollar ve orman patikaları boyunca ilerleyerek ziyaretçilere şehrin yoğunluğundan uzaklaşma fırsatı sunar.\n\nDoğa fotoğrafçılığı, manzara izleme ve açık havada vakit geçirmek isteyenler için değerlendirilebilecek bu rota, çevredeki tepeler ve kırsal yürüyüş güzergâhlarıyla birleştirilebilir.',
      'summary_en':
          'Located around Denizli Neighborhood in Gebze, Denizli Pond combines lake views with rural nature. Trails along dirt roads and forest paths offer a serene escape from city hustle.',
      'summary_ar':
          'تقع بركة دينيزلي بالقرب من حي دينيزلي في جبزة، وتجمع بين إطلالة البحيرة الهادئة والطبيعة الريفية مع مسارات المشي عبر الطرق الترابية والغابات.',
      'type': 'doga',
      'village': 'Denizli Mahallesi',
      'address': 'Denizli Mahallesi, Gebze, Kocaeli',
      'mapQuery': 'Denizli Göleti Gebze Kocaeli',
      'image': 'gorsel/piknik/denizli_goleti.jpg',
      'features': ['Gölet Manzarası', 'Kırsal Doğa', 'Orman Yürüyüşü', 'Fotoğrafçılık'],
      'features_en': ['Lake View', 'Rural Nature', 'Forest Walk', 'Photography'],
      'features_ar': ['إطلالة البركة', 'طبيعة ريفية', 'مشي في الغابة', 'تصوير'],
      'order': 2,
    },
    {
      'id': 'doga_denizli_yoruk_yaylalari',
      'name': 'Denizli Göleti – Yörük Yaylaları Doğa Rotası',
      'name_en': 'Denizli Pond – Yoruk Plateaus Nature Route',
      'name_ar': 'مسار بركة دينيزلي – هضاب يوروك الطبيعي',
      'summary':
          'Denizli Göleti\'nden başlayarak Gebze\'nin kırsal alanlarına uzanan bu doğa rotası; orman yollarını, geniş çayırlıkları ve yayla manzaralarını bir araya getirir. Şehir yaşamından uzaklaşmak, doğanın sakinliğini hissetmek ve uzun yürüyüşler yapmak isteyenler için farklı bir keşif deneyimi sunar.\n\nGüzergâhın seçilen bölümüne göre yürüyüş, gölet çevresinden tepelere ve yayla açıklıklarına doğru ilerleyebilir. Doğa yürüyüşü grupları tarafından kullanılan bu bölge, kırsal manzara ve doğa fotoğrafçılığı açısından da ilgi çekicidir.',
      'summary_en':
          'Starting from Denizli Pond and extending into rural Gebze, this nature route combines forest tracks, wide meadows, and plateau views, offering a great experience for hiking groups.',
      'summary_ar':
          'يمتد هذا المسار الطبيعي من بركة دينيزلي نحو ريف جبزة، جامعاً بين طرق الغابات والمروج الخضراء الواسعة وإطلالات الهضاب الخلابة.',
      'type': 'doga',
      'village': 'Denizli & Yörük Yaylaları',
      'address': 'Denizli Mahallesi ve Yörük Yaylaları çevresi, Gebze, Kocaeli',
      'mapQuery': 'Denizli Göleti Yörük Yaylaları Gebze Kocaeli',
      'image': 'gorsel/piknik/denizli_yoruk_yaylalari.png',
      'features': ['Yayla Manzaraları', 'Orman Patikaları', 'Çayırlıklar', 'Uzun Doğa Yürüyüşleri'],
      'features_en': ['Plateau Views', 'Forest Trails', 'Meadows', 'Long Nature Walks'],
      'features_ar': ['مناظر الهضاب', 'مسارات الغابات', 'مروج خضراء', 'مشي طبيعي طويل'],
      'order': 3,
    },
    {
      'id': 'doga_elmalidere_selalesi',
      'name': 'Elmalıdere Şelalesi ve Orman Patikaları',
      'name_en': 'Elmalidere Waterfall & Forest Trails',
      'name_ar': 'شلال إلماليده ره ومسارات الغابة',
      'summary':
          'Gebze\'nin Denizli kırsalı çevresinde bulunan Elmalıdere Şelalesi, dere yatağı, doğal bitki örtüsü ve orman yollarıyla doğa yürüyüşü meraklılarının ilgisini çeken bir noktadır. Bölgeye uzanan güzergâhlar, yürüyüş boyunca farklı arazi dokularını ve kırsal manzaraları keşfetme imkânı sunar.\n\nŞelaleye ulaşan patikalar, doğa fotoğrafçılığı ve sakin bir açık hava deneyimi arayanlar için ilgi çekici olabilir. Bununla birlikte arazi koşulları, su seviyesi ve erişim durumu mevsime göre değişebileceğinden ziyaret öncesinde güzergâhın güncel durumu kontrol edilmelidir.',
      'summary_en':
          'Located around Denizli countryside in Gebze, Elmalidere Waterfall attracts hiking enthusiasts with its stream bed, natural flora, and forest paths.\n\nNote: Seasonal terrain conditions and water levels may vary.',
      'summary_ar':
          'يقع شلال إلماليده ره في ريف دينيزلي بجبزة، ويجذب عشاق المشي الطبيعي بمجراه المائي وغطائه النباتي ومساراته بين الغابات.',
      'type': 'doga',
      'village': 'Denizli Kırsalı',
      'address': 'Denizli kırsalı, Gebze, Kocaeli',
      'mapQuery': 'Elmalıdere Şelalesi Denizli Gebze Kocaeli',
      'image': 'gorsel/piknik/elmalidere_selalesi.jpg',
      'features': ['Şelale Manzarası', 'Dere Yatağı', 'Orman Patikaları', 'Doğa Fotoğrafçılığı'],
      'features_en': ['Waterfall View', 'Stream Bed', 'Forest Paths', 'Nature Photography'],
      'features_ar': ['إطلالة الشلال', 'مجرى مائي', 'مسارات الغابة', 'تصوير الطبيعة'],
      'order': 4,
    },
    {
      'id': 'doga_yelken_tepe',
      'name': 'Yelken Tepe Doğa Yürüyüşü',
      'name_en': 'Yelken Tepe Nature Walk',
      'name_ar': 'مسار جبل يلكن تيبي',
      'summary':
          'Gebze\'nin Denizli kırsalındaki Yelken Tepe, gölet ve yayla güzergâhlarıyla birleştirilebilen bir doğa yürüyüşü noktasıdır. Orman içinden geçen patikalar ve yükseltilerden görülen kırsal manzaralar, yürüyüşe farklı bir deneyim katar.\n\nTepeye uzanan güzergâhlar, doğada vakit geçirmek, manzara fotoğrafları çekmek ve daha uzun yürüyüş parkurlarını keşfetmek isteyenlere hitap eder. Arazi yapısı ve seçilen parkura bağlı olarak yürüyüş, başlangıç seviyesinden daha deneyimli doğa yürüyüşçülerine kadar farklı hazırlık düzeyleri gerektirebilir.',
      'summary_en':
          'Yelken Tepe in rural Denizli, Gebze is a peak hiking spot featuring paths through forest terrain and rewarding panoramic rural vistas.',
      'summary_ar':
          'تعتبر قمة يلكن تيبي في ريف دينيزلي بجبزة وجهة مميزة للمشي الجبلي والمسارات الغابية والمناظر الريفية البانورامية.',
      'type': 'doga',
      'village': 'Denizli Kırsalı',
      'address': 'Yelken Tepe, Denizli kırsalı, Gebze, Kocaeli',
      'mapQuery': 'Yelken Tepe Denizli Gebze Kocaeli',
      'image': 'gorsel/piknik/yelken_tepe.png',
      'features': ['Tepe Yürüyüşü', 'Orman Patikaları', 'Kırsal Manzara', 'Fotoğrafçılık'],
      'features_en': ['Hill Trek', 'Forest Paths', 'Rural Scenery', 'Photography'],
      'features_ar': ['صعود التل', 'مسارات الغابة', 'مشهد ريفي', 'تصوير'],
      'order': 5,
    },
    {
      'id': 'fb_eskihisar',
      'name': 'Eskihisar Korusu',
      'type': 'piknik',
      'village': 'Eskihisar',
      'address': 'Eskihisar, Gebze',
      'mapQuery': 'Eskihisar Korusu Gebze',
      'image': 'gorsel/piknik/eskoru.webp',
      'features': ['Piknik', 'Koru', 'Deniz Manzarası'],
      'order': 6,
    },
    {
      'id': 'fb_pelitli',
      'name': 'Pelitli Bayraktepe Mesire Alanı',
      'type': 'mesire',
      'village': 'Pelitli',
      'address': 'Pelitli, Gebze',
      'mapQuery': 'Gebze Belediyesi Pelitli Bayraktepe Mesire Alanı',
      'image': 'gorsel/piknik/pelitlimesire.webp',
      'features': ['Mesire Alanı', 'Seyir Tepesi'],
      'order': 7,
    },
    {
      'id': 'fb_gazilerdagi',
      'name': 'Gazilerdağı Tabiat Parkı',
      'type': 'doga',
      'village': 'Gaziler',
      'address': 'Gaziler, Gebze',
      'mapQuery': 'Gazilerdağı Tabiat Parkı Gebze',
      'image': 'gorsel/piknik/gazilerdağı.webp',
      'features': ['Tabiat Parkı', 'Yürüyüş Parkuru'],
      'order': 8,
    },
    {
      'id': 'fb_gaziler_piknik',
      'name': 'Gaziler Piknik Alanı',
      'type': 'piknik',
      'village': 'Gaziler',
      'address': 'Dicle Cd. No:48, Gaziler',
      'mapQuery': 'Gaziler piknik alanı Gebze',
      'image': 'gorsel/piknik/gazilerpiknik.webp',
      'features': ['Piknik Masaları', 'Çardaklar'],
      'order': 9,
    },
    {
      'id': 'fb_cumakoy',
      'name': 'Cumaköy Mesire Alanı',
      'type': 'mesire',
      'village': 'Cumaköy',
      'address': 'Cumaköy, Gebze',
      'mapQuery': 'Gebze Belediyesi Cumaköy Mesire Alanı',
      'image': 'gorsel/piknik/cumakoymesire.jpg',
      'features': ['Mesire Alanı', 'Ağaçlık Alan'],
      'order': 10,
    },
    {
      'id': 'fb_duzmese',
      'name': 'Düz Meşe Mesire Yeri',
      'type': 'mesire',
      'village': 'Gebze',
      'address': 'Gebze / Kocaeli',
      'mapQuery': 'Düz Meşe Mesire Yeri Gebze',
      'image': 'gorsel/piknik/duzmese.webp',
      'features': ['Meşe Ormanı', 'Piknik'],
      'order': 11,
    },
    {
      'id': 'fb_tatlikuyu',
      'name': 'Tatlıkuyu Vadisi',
      'type': 'park',
      'village': 'Tatlıkuyu',
      'address': '1312/1. Sk. No:20',
      'mapQuery': 'Tatlıkuyu Vadisi Gebze',
      'image': 'gorsel/piknik/tatlikuyu.webp',
      'features': ['Kent Parkı', 'Yürüyüş Yolu'],
      'order': 12,
    },
    {
      'id': 'fb_gaziler_parki',
      'name': 'Gaziler Parkı',
      'type': 'park',
      'village': 'Gaziler',
      'address': 'Şht. Özcan Demirci Cd. No:50',
      'mapQuery': 'Gaziler Parkı Gebze',
      'image': 'gorsel/piknik/gazilerpiknik.webp',
      'features': ['Park', 'Çocuk Oyun Alanı'],
      'order': 13,
    },
    {
      'id': 'fb_yumrukaya',
      'name': 'Yumrukaya Piknik Alanı',
      'type': 'piknik',
      'village': 'Yumrukaya',
      'address': 'İbrahim Ağa Cd.',
      'mapQuery': 'Yumrukaya Piknik Alanı Gebze',
      'image': 'gorsel/piknik/eskoru.webp',
      'features': ['Piknik', 'Yeşil Alan'],
      'order': 14,
    },
    {
      'id': 'fb_ballikayalar',
      'name': 'Ballıkayalar Tabiat Parkı',
      'type': 'doga',
      'village': 'Tavşanlı',
      'address': 'Barış Cd., Tavşanlı Köyü',
      'mapQuery': 'Ballıkayalar Tabiat Parkı Gebze',
      'image': 'gorsel/piknik/ballikayapark.webp',
      'features': ['Kanyon', 'Kaya Tırmanışı', 'Doğa Yürüyüşü', 'Şelale'],
      'order': 15,
    },
  ];

  return [
    for (int i = 0; i < items.length; i++)
      GebzePicnic(
        items[i]['id'] as String,
        items[i],
        fallbackOrder: items[i]['order'] as int? ?? i,
      ),
  ];
}

// ───────────────────────── Liste ─────────────────────────

class GuidePicnicView extends StatefulWidget {
  final String lang;
  const GuidePicnicView({super.key, required this.lang});

  @override
  State<GuidePicnicView> createState() => _GuidePicnicViewState();
}

class _GuidePicnicViewState extends State<GuidePicnicView> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _type = 'all';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_t(widget.lang, 'Sayfa açılamadı.',
                'Could not open the page.', 'تعذّر فتح الصفحة.')),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filters = ['all', ..._types];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : _C.field,
              borderRadius: BorderRadius.circular(24),
              border:
                  isDark ? Border.all(color: const Color(0xFF334155)) : null,
            ),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(
                  fontSize: 14, color: isDark ? Colors.white : _C.textDark),
              decoration: InputDecoration(
                filled: false,
                hintText: _t(lang, 'Piknik, mesire veya doğa alanı ara...',
                    'Search picnic, recreation or nature areas...',
                    'ابحث عن منطقة نزهة أو طبيعة...'),
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (int i = 0; i < filters.length; i++) ...[
                if (i != 0) const SizedBox(width: 6),
                Expanded(
                  child: Builder(builder: (context) {
                    final f = filters[i];
                    final isSel = f == _type;
                    return ChoiceChip(
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _typeChipLabel(f, lang),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel
                                  ? Colors.white
                                  : (isDark ? Colors.white : _C.textDark),
                            ),
                          ),
                        ),
                      ),
                      selected: isSel,
                      selectedColor:
                          isDark ? const Color(0xFF2563EB) : _C.navy,
                      backgroundColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      side: BorderSide(
                        color: isSel
                            ? (isDark ? const Color(0xFF2563EB) : _C.navy)
                            : (isDark ? const Color(0xFF334155) : _C.line),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _type = f),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('guide_picnic')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              final Map<String, GebzePicnic> byId = {
                for (final p in _fallbackPicnic()) p.id: p,
              };
              for (final d in docs) {
                byId[d.id] = GebzePicnic(d.id, d.data());
              }
              final all = byId.values.toList()
                ..sort((a, b) => a.order.compareTo(b.order));

              final q = _query.trim().toLowerCase();
              final filtered = all.where((p) {
                final okType = _type == 'all' || p.type == _type;
                final okQuery = q.isEmpty ||
                    p.text('name', lang).toLowerCase().contains(q) ||
                    p.text('summary', lang).toLowerCase().contains(q) ||
                    p.text('village', lang).toLowerCase().contains(q) ||
                    p.text('address', lang).toLowerCase().contains(q);
                return okType && okQuery;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _t(lang, 'Alan bulunamadı.', 'No areas found.',
                          'لم يتم العثور على أماكن.'),
                      style: const TextStyle(
                          color: _C.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _PicnicCard(
                  item: filtered[i],
                  lang: lang,
                  onDirections: () => _open(filtered[i].directionsUrl),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Görsel ─────────────────────────

class _PicnicImage extends StatelessWidget {
  final String image;
  final String type;
  final double height;
  const _PicnicImage(
      {required this.image, required this.type, required this.height});

  Widget _placeholder() => Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF66BB6A), Color(0xFF1B5E20)],
          ),
        ),
        child: Center(
          child: Icon(_typeIcon(type), color: Colors.white70, size: 56),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (image.trim().isEmpty) return _placeholder();
    final p = _norm(image);
    if (p.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: p,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, _) => _placeholder(),
        errorWidget: (_, _, _) => _placeholder(),
      );
    }
    return Image.asset(
      p,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }
}

// ───────────────────────── Kart ─────────────────────────

class _PicnicCard extends StatelessWidget {
  final GebzePicnic item;
  final String lang;
  final VoidCallback onDirections;
  const _PicnicCard({
    required this.item,
    required this.lang,
    required this.onDirections,
  });

  void _showDetailSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = item.text('summary', lang);
    final village = item.text('village', lang);
    final address = item.text('address', lang);
    final features = item.list('features', lang);
    final place = [village, address].where((s) => s.isNotEmpty).join(' • ');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _PicnicImage(
                      image: item.image,
                      type: item.type,
                      height: 220,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _C.green,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_typeIcon(item.type),
                                size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              _typeLabel(item.type, lang),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.text('name', lang),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : _C.textDark,
                    ),
                  ),
                  if (place.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 18, color: _C.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            place,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : _C.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      _t(lang, 'Açıklama & Rota Bilgisi',
                          'Description & Route Info', 'الوصف ومعلومات المسار'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ],
                  if (features.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      _t(lang, 'Öne Çıkanlar & Aktiviteler',
                          'Highlights & Activities', 'الأنشطة والمميزات'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in features)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: _C.green.withAlpha(80)),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFA5D6A7)
                                    : _C.green,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onDirections();
                      },
                      icon: const Icon(Icons.directions_rounded, size: 20),
                      label: Text(
                        _t(lang, 'Haritada Yol Tarifi Al',
                            'Get Directions on Map', 'الاتجاهات على الخريطة'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = item.text('summary', lang);
    final village = item.text('village', lang);
    final address = item.text('address', lang);
    final features = item.list('features', lang);
    final place = [village, address].where((s) => s.isNotEmpty).join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : _C.line),
      ),
      child: InkWell(
        onTap: () => _showDetailSheet(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _PicnicImage(image: item.image, type: item.type, height: 160),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _C.green.withAlpha(230),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_typeIcon(item.type),
                            size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          _typeLabel(item.type, lang),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text('name', lang),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: isDark ? Colors.white : _C.textDark,
                    ),
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t(lang, 'Detayları ve rota bilgilerini gör →',
                          'View details and route info →', 'عرض التفاصيل والمعلومات →'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                  if (place.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 16, color: _C.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            place,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : _C.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (features.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final f in features)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFA5D6A7)
                                    : _C.green,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: Text(
                        _t(lang, 'Yol Tarifi', 'Directions', 'الاتجاهات'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}