import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Gebze Belediyesi - Şehir Rehberi
/// Dosya yolu: lib/screens/guide_screen.dart
///
/// İki sekme:
///  1) Kurumsal Hizmetler -> kategori listesi (tıklayınca kurum listesi açılır)
///  2) Gebze'yi Keşfet    -> tarihi / doğa / müze / cami kartları
///
/// Firestore koleksiyonları (opsiyonel, yoksa yedek veriler gösterilir):
///  - guide_places       : name, summary, category, image, detailUrl, distanceKm
///  - guide_institutions : name, category (parklar|lokantalar|pazar|spor|kultur|belediye),
///                         address, phone, description

class _C {
  static const navy = Color(0xFF0A2A66);
  static const navyDeep = Color(0xFF0F2240);
  static const orange = Color(0xFFFF7A00);
  static const bg = Color(0xFFF7F9FE);
  static const line = Color(0xFFE4E9F2);
  static const field = Color(0xFFEEF2FA);
  static const textDark = Color(0xFF0A1F44);
  static const textMuted = Color(0xFF5F6F8A);
}

const String _kBodyFont = 'Poppins';
const List<String> _kBodyFontFallback = ['Roboto', 'Noto Sans', 'sans-serif'];

Widget _withFont(BuildContext context, Widget child) {
  final base = Theme.of(context);
  return Theme(
    data: base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: _kBodyFont,
        fontFamilyFallback: _kBodyFontFallback,
      ),
    ),
    child: child,
  );
}

Future<void> _openUrl(BuildContext context, String url) async {
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  ).catchError((_) => false);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Sayfa açılamadı. Lütfen tekrar deneyin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

// ───────────────────────── Modeller ─────────────────────────

class HistoricPlace {
  final String id;
  final String name;
  final String summary;
  final String detailUrl;

  /// Tarihi | Müzeler | Doğa | Camiler
  final String category;

  /// `gorsel/...` asset yolu veya `https://...` adresi.
  final String? image;
  final double? distanceKm;

  const HistoricPlace({
    required this.id,
    required this.name,
    required this.summary,
    required this.detailUrl,
    required this.category,
    this.image,
    this.distanceKm,
  });

  IconData get icon {
    switch (category) {
      case 'Camiler':
        return Icons.mosque_rounded;
      case 'Müzeler':
        return Icons.museum_rounded;
      case 'Doğa':
        return Icons.landscape_rounded;
      default:
        return Icons.castle_rounded;
    }
  }

  factory HistoricPlace.fromMap(String id, Map<String, dynamic> m) {
    return HistoricPlace(
      id: id,
      name: (m['name'] ?? '').toString(),
      summary: (m['summary'] ?? '').toString(),
      detailUrl: (m['detailUrl'] ?? '').toString(),
      category: (m['category'] ?? 'Tarihi').toString(),
      image: m['image']?.toString(),
      distanceKm: (m['distanceKm'] as num?)?.toDouble(),
    );
  }
}

class _Category {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  const _Category(this.id, this.title, this.icon, this.color);
}

const List<_Category> _categories = [
  _Category('parklar', 'Parklar ve Kütüphaneler', Icons.park_rounded,
      Color(0xFF43A047)),
  _Category('lokantalar', 'Kent Lokantaları', Icons.restaurant_rounded,
      Color(0xFFFB8C00)),
  _Category('pazar', 'Pazar Yerleri', Icons.shopping_basket_rounded,
      Color(0xFFFFB300)),
  _Category('spor', 'Spor Tesisleri', Icons.sports_soccer_rounded,
      Color(0xFF1E88E5)),
  _Category('kultur', 'Kültür Merkezleri', Icons.museum_rounded,
      Color(0xFF8E24AA)),
  _Category('belediye', 'Belediye Tesisleri', Icons.account_balance_rounded,
      Color(0xFF0A2A66)),
];

const List<HistoricPlace> _fallbackPlaces = [
  HistoricPlace(
    id: 'cmp_camii',
    name: 'Çoban Mustafa Paşa Camii ve Külliyesi',
    summary:
        'Çoban Mustafa Paşa\'nın 1523\'te yaptırdığı cami ve külliye, Gebze\'nin en önemli Osmanlı eserlerinden biridir.',
    detailUrl:
        'https://www.gebze.bel.tr/gebze-tarihi-yerler_coban-mustafa-pasa-camii-ve-kulliyesi_1.html',
    image: 'gorsel/tarihi_yerler/cmpasa.jpg',
    category: 'Camiler',
  ),
  HistoricPlace(
    id: 'sultan_orhan',
    name: 'Sultan Orhan Camii',
    summary:
        'Yaklaşık 1323-1331 yıllarında Orhan Bey tarafından yaptırılan, ilk dönem Osmanlı mimarisinin sade bir örneği.',
    detailUrl: 'https://www.gebze.bel.tr/gebze/sultan-orhan-camii_2.html',
    image: 'gorsel/tarihi_yerler/sorhan.jpg',
    category: 'Camiler',
  ),
  HistoricPlace(
    id: 'ilyas_bey',
    name: 'İlyas Bey Camii',
    summary:
        'Osmanlı\'dan kalan en eski cami olarak kabul edilir. Kubbesizdir, girişinde sülüs yazılı bir kitabe bulunur.',
    detailUrl:
        'https://www.gebze.bel.tr/gebze-tarihi-yerler_ilyas-bey-camii_3.html',
    image: 'gorsel/tarihi_yerler/ilyasb.jpg',
    category: 'Camiler',
  ),
  HistoricPlace(
    id: 'anibal',
    name: 'Anibal\'ın (Hannibal) Mezarı',
    summary:
        'Selvilerle çevrili alanda duran 24 tonluk taş lahit, beş dilde yazılmış kitabelerle komutanın hayatını anlatır.',
    detailUrl:
        'https://www.gebze.bel.tr/gebze-tarihi-yerler_anibalin-mezari_4.html',
    image: 'gorsel/tarihi_yerler/anibal.jpg',
    category: 'Tarihi',
  ),
  HistoricPlace(
    id: 'hunkar',
    name: 'Hünkar Çayırı',
    summary:
        'Fatih Sultan Mehmet\'in 1481\'de ordusunu dinlendirdiği çayırlık alan. Bugün park olarak düzenlenmiştir.',
    detailUrl:
        'https://www.gebze.bel.tr/gebze-tarihi-yerler_hunkar-cayiri_5.html',
    image: 'gorsel/tarihi_yerler/hunkar.jpg',
    category: 'Doğa',
  ),
  HistoricPlace(
    id: 'osman_hamdi',
    name: 'Osman Hamdi Bey Yalısı',
    summary:
        'Osman Hamdi Bey\'in 1884\'te Eskihisar\'da yaptırdığı iki katlı yalı, bugün müze olarak ziyaret edilebiliyor.',
    detailUrl:
        'https://www.gebze.bel.tr/gebze-tarihi-yerler_osman-hamdi-bey-yalisi_6.html',
    image: 'gorsel/tarihi_yerler/osmanbey.jpg',
    category: 'Müzeler',
  ),
  HistoricPlace(
    id: 'eskihisar_kalesi',
    name: 'Eskihisar Kalesi',
    summary:
        'Bizans döneminden kalma tarihi kale. 10 burcu ve 4 kapısıyla özgün yapısını büyük ölçüde korur.',
    detailUrl: 'https://www.gebze.bel.tr/gebze/eskihisar-kalesi_7.html',
    image: 'gorsel/tarihi_yerler/eskale.jpg',
    category: 'Tarihi',
  ),
  HistoricPlace(
    id: 'ballikayalar',
    name: 'Ballıkayalar',
    summary:
        'Karstik vadi; göletleri, şelaleleri, travertenleri ve çok sayıda mağarasıyla doğal güzelliğiyle öne çıkar.',
    detailUrl:
        'https://www.gebze.bel.tr/gebze-tarihi-yerler_ballikayalar_8.html',
    image: 'gorsel/tarihi_yerler/ballikaya.jpg',
    category: 'Doğa',
  ),
  HistoricPlace(
    id: 'ibrahim_pasa_cesmesi',
    name: 'İbrahim Paşa Çeşmesi (Çarşı Çeşmesi)',
    summary:
        '1664\'te yaptırılan kare planlı çeşme, kent merkezinde Çoban Mustafa Paşa Hamamı\'nın yanındadır.',
    detailUrl:
        'https://www.gebze.bel.tr/gebze-tarihi-yerler_ibrahim-pasa-cesmesi-carsi-cesmesi_9.html',
    image: 'gorsel/tarihi_yerler/ipasacesmesi.jpg',
    category: 'Tarihi',
  ),
  HistoricPlace(
    id: 'sadirvan',
    name: 'Çoban Mustafa Paşa Şadırvanı',
    summary:
        'Külliyenin ortasındaki on iki kenarlı şadırvan, her köşesinde bir musluk bulunur ve piramit çatıyla örtülüdür.',
    detailUrl:
        'https://www.gebze.bel.tr/gebze-tarihi-yerler_coban-mustafa-pasa-sadirvani_10.html',
    image: 'gorsel/tarihi_yerler/sadirvan.jpg',
    category: 'Tarihi',
  ),
  HistoricPlace(
    id: 'eskihisar_cesmesi',
    name: 'Eskihisar Çeşmesi',
    summary:
        '1772\'de yaptırılan, kare planlı ve piramit çatılı çeşme. 1850\'de kapsamlı bir onarım görmüştür.',
    detailUrl:
        'https://www.gebze.bel.tr/gebze-tarihi-yerler_eskihisar-cesmesi_11.html',
    image: 'gorsel/tarihi_yerler/escesme.jpg',
    category: 'Tarihi',
  ),
  HistoricPlace(
    id: 'hamam',
    name: 'Çoban Mustafa Paşa Hamamı',
    summary:
        '1523\'te yaptırılan, Çarşı Hamamı ve Çifte Hamam olarak bilinen iki kubbeli yapı Gebze\'nin en büyüğüdür.',
    detailUrl:
        'https://www.gebze.bel.tr/gebze-tarihi-yerler_coban-mustafa-pasa-hamami_12.html',
    image: 'gorsel/tarihi_yerler/hamam.jpg',
    category: 'Tarihi',
  ),
];

// ───────────────────────── Ana Ekran ─────────────────────────

class GuideScreen extends StatelessWidget {
  /// Alt menüde başka sekmeye geçilmek istendiğinde çağrılır.
  /// (0: Ana Sayfa, 1: Rehber, 2: Bildir, 3: Hizmetler, 4: Profil)
  final ValueChanged<int>? onNavTap;

  const GuideScreen({super.key, this.onNavTap});

  @override
  Widget build(BuildContext context) {
    return _withFont(
      context,
      AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light
            .copyWith(statusBarColor: Colors.transparent),
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: _C.bg,
            body: Column(
              children: [
                const _Header(),
                const Expanded(
                  child: TabBarView(
                    children: [
                      _InstitutionsTab(),
                      _DiscoverTab(),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _BottomNav(
              index: 1,
              onTap: (i) => onNavTap?.call(i),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _C.navyDeep,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Şehir Rehberi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const TabBar(
              indicatorColor: _C.orange,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
              tabs: [
                Tab(text: 'Kurumsal Hizmetler'),
                Tab(text: 'Gebze\'yi Keşfet'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Ortak arama kutusu ─────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _C.field,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14, color: _C.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _C.textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _C.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ───────────────────────── Sekme 1: Kurumsal Hizmetler ─────────────────────────

class _InstitutionsTab extends StatefulWidget {
  const _InstitutionsTab();

  @override
  State<_InstitutionsTab> createState() => _InstitutionsTabState();
}

class _InstitutionsTabState extends State<_InstitutionsTab>
    with AutomaticKeepAliveClientMixin {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? _categories
        : _categories.where((c) => c.title.toLowerCase().contains(q)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _SearchField(
            controller: _ctrl,
            hint: 'Hizmet veya birim ara...',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'Aradığınız birim bulunamadı',
                    style: TextStyle(
                        color: _C.textMuted, fontWeight: FontWeight.w600),
                  ),
                )
              : ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _CategoryTile(
                    category: items[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            _InstitutionListScreen(category: items[i]),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _Category category;
  final VoidCallback onTap;
  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _C.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category.color.withAlpha(32),
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, color: category.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  category.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _C.textDark,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _C.textMuted, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bir kategoriye tıklayınca açılan kurum listesi (Firestore: guide_institutions).
class _InstitutionListScreen extends StatelessWidget {
  final _Category category;
  const _InstitutionListScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return _withFont(
      context,
      Scaffold(
        backgroundColor: _C.bg,
        appBar: AppBar(
          backgroundColor: _C.navyDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            category.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('guide_institutions')
              .where('category', isEqualTo: category.id)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data?.docs ?? [];
            if (snap.hasError || docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Bu kategori için henüz kayıt eklenmedi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _C.textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _InstitutionCard(data: docs[i].data(), color: category.color),
            );
          },
        ),
      ),
    );
  }
}

class _InstitutionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color color;
  const _InstitutionCard({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? '').toString();
    final address = (data['address'] ?? '').toString();
    final phone = (data['phone'] ?? '').toString();
    final desc = (data['description'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _C.textDark),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc,
                style: const TextStyle(
                    fontSize: 12.5, height: 1.4, color: _C.textMuted)),
          ],
          if (address.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(address,
                      style: const TextStyle(
                          fontSize: 12.5, color: _C.textDark)),
                ),
              ],
            ),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _openUrl(context, 'tel:$phone'),
              child: Row(
                children: [
                  Icon(Icons.phone_rounded, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(phone,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── Sekme 2: Gebze'yi Keşfet ─────────────────────────

class _DiscoverTab extends StatefulWidget {
  const _DiscoverTab();

  @override
  State<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<_DiscoverTab>
    with AutomaticKeepAliveClientMixin {
  static const _filters = ['Tümü', 'Tarihi', 'Müzeler', 'Doğa', 'Camiler'];

  final _ctrl = TextEditingController();
  String _query = '';
  String _filter = 'Tümü';
  final Set<String> _favorites = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<HistoricPlace> _applyFilters(List<HistoricPlace> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      final okCat = _filter == 'Tümü' || p.category == _filter;
      final okQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.summary.toLowerCase().contains(q);
      return okCat && okQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: _ctrl,
                  hint: 'Mekan, müze veya park ara...',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: _C.field,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _openUrl(
                    context,
                    'https://www.google.com/maps/search/?api=1&query=Gebze+tarihi+yerler',
                  ),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.map_outlined, color: _C.textDark),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final selected = _filters[i] == _filter;
              return ChoiceChip(
                label: Text(_filters[i]),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) => setState(() => _filter = _filters[i]),
                selectedColor: _C.navyDeep,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _C.textDark,
                ),
                shape: StadiumBorder(
                  side: BorderSide(color: selected ? _C.navyDeep : _C.line),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance.collection('guide_places').snapshots(),
            builder: (context, snap) {
              // Firestore'da kayıt varsa onu, yoksa yedek listeyi göster.
              final List<HistoricPlace> all =
                  (snap.hasData && snap.data!.docs.isNotEmpty)
                      ? snap.data!.docs
                          .map((d) => HistoricPlace.fromMap(d.id, d.data()))
                          .toList()
                      : _fallbackPlaces;

              final items = _applyFilters(all);
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    'Aradığınız yer bulunamadı',
                    style: TextStyle(
                        color: _C.textMuted, fontWeight: FontWeight.w600),
                  ),
                );
              }
              return ListView.builder(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final p = items[i];
                  return _PlaceCard(
                    place: p,
                    isFavorite: _favorites.contains(p.id),
                    onFavorite: () => setState(() {
                      if (!_favorites.add(p.id)) _favorites.remove(p.id);
                    }),
                    onTap: p.detailUrl.isEmpty
                        ? null
                        : () => _openUrl(context, p.detailUrl),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlaceImage extends StatelessWidget {
  final HistoricPlace place;
  final double height;
  const _PlaceImage({required this.place, required this.height});

  Widget _placeholder() => Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2F6FDB), Color(0xFF0A2A66)],
          ),
        ),
        child: Center(
          child: Icon(place.icon, color: Colors.white54, size: 56),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final img = place.image;
    if (img == null || img.isEmpty) return _placeholder();

    if (img.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: img,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }

    return Image.asset(
      img,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final HistoricPlace place;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback? onTap;
  const _PlaceCard({
    required this.place,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.line),
      ),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _PlaceImage(place: place, height: 170),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _C.navyDeep.withAlpha(220),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        place.category,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onFavorite,
                        child: SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: const Color(0xFFE53935),
                            size: 22,
                          ),
                        ),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _C.textDark,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (place.distanceKm != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F4FB),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 14, color: Color(0xFF0288D1)),
                                const SizedBox(width: 3),
                                Text(
                                  '${place.distanceKm!.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0288D1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      place.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: _C.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Alt Menü ─────────────────────────

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  static const _items = <_NavItem>[
    _NavItem('ANA SAYFA', Icons.home_rounded),
    _NavItem('REHBER', Icons.explore_outlined),
    _NavItem('BİLDİR', Icons.photo_camera_outlined),
    _NavItem('HİZMETLER', Icons.grid_view_rounded),
    _NavItem('PROFİL', Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _C.navyDeep,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Row(
            children: [
              for (int i = 0; i < _items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _items[i].icon,
                          size: 28,
                          color: i == index ? _C.orange : Colors.white70,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _items[i].label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight:
                                i == index ? FontWeight.w800 : FontWeight.w500,
                            color: i == index ? _C.orange : Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 64,
                          height: 3,
                          decoration: BoxDecoration(
                            color: i == index ? _C.orange : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}