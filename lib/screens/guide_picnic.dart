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
///   features, features_en, features_ar -> List<String> (ör. çardak, otopark)
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
  const rows = <List<String>>[
    // [ad, tür, adres/köy, mapQuery]
    ['Eskihisar Korusu', 'piknik', 'Eskihisar', 'Eskihisar Korusu Gebze'],
    ['Pelitli Bayraktepe Mesire Alanı', 'mesire', 'Pelitli', 'Gebze Belediyesi Pelitli Bayraktepe Mesire Alanı'],
    ['Gazilerdağı Tabiat Parkı', 'doga', 'Gaziler', 'Gazilerdağı Tabiat Parkı Gebze'],
    ['Gaziler Piknik Alanı', 'piknik', 'Dicle Cd. No:48, Gaziler', 'Gaziler piknik alanı Gebze'],
    ['Cumaköy Mesire Alanı', 'mesire', 'Cumaköy', 'Gebze Belediyesi Cumaköy Mesire Alanı'],
    ['Düz Meşe Mesire Yeri', 'mesire', 'Gebze / Kocaeli', 'Düz Meşe Mesire Yeri Gebze'],
    ['Tatlıkuyu Vadisi', 'park', '1312/1. Sk. No:20', 'Tatlıkuyu Vadisi Gebze'],
    ['Gaziler Parkı', 'park', 'Şht. Özcan Demirci Cd. No:50', 'Gaziler Parkı Gebze'],
    ['Yumrukaya Piknik Alanı', 'piknik', 'İbrahim Ağa Cd.', 'Yumrukaya Piknik Alanı Gebze'],
    ['Ballıkayalar Tabiat Parkı', 'doga', 'Barış Cd.', 'Ballıkayalar Tabiat Parkı Gebze'],
  ];
  return [
    for (int i = 0; i < rows.length; i++)
      GebzePicnic(
        'fb_$i',
        {
          'name': rows[i][0],
          'type': rows[i][1],
          'address': rows[i][2],
          'mapQuery': rows[i][3],
        },
        fallbackOrder: i,
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
              final all = docs.isEmpty
                  ? _fallbackPicnic()
                  : (docs.map((d) => GebzePicnic(d.id, d.data())).toList()
                    ..sort((a, b) => a.order.compareTo(b.order)));

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
                      Icon(_typeIcon(item.type), size: 14, color: Colors.white),
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
    );
  }
}