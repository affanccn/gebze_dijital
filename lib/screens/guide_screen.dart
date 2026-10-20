import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_guard.dart';
import 'favorites_service.dart';
import '../core/localization/app_strings.dart';

/// Gebze Belediyesi - Şehir Rehberi
/// Dosya yolu: lib/screens/guide_screen.dart

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
  final isDark = base.brightness == Brightness.dark;
  return Theme(
    data: base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: _kBodyFont,
        fontFamilyFallback: _kBodyFontFallback,
        bodyColor: isDark ? Colors.white : const Color(0xFF0A1F44),
        displayColor: isDark ? Colors.white : const Color(0xFF0A1F44),
      ),
    ),
    child: child,
  );
}

/// Önizleme sayfasındaki yeni metinler için yerel çeviri yardımcısı.
/// (İstersen bunları ileride AppStrings dosyasına taşıyabilirsiniz.)
String _t(String lang, String tr, String en, String ar) =>
    lang == 'en' ? en : (lang == 'ar' ? ar : tr);

/// Windows'tan kopyalanan "gorsel\tesisler\x.jpg" yollarını "gorsel/tesisler/x.jpg" yapar.
String _normalizeImagePath(String path) => path.trim().replaceAll('\\', '/');

Future<void> _openUrl(BuildContext context, String url, String lang) async {
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  ).catchError((_) => false);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('page_open_error', lang)),
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
  final String category;
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
      case 'Mosques':
      case 'مساجد':
        return Icons.mosque_rounded;
      case 'Müzeler':
      case 'Museums':
      case 'متاحف':
        return Icons.museum_rounded;
      case 'Doğa':
      case 'Nature':
      case 'طبيعة':
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

List<_Category> _getCategories(String lang) => [
  _Category(
    'etkinlikler',
    AppStrings.get('cat_events', lang),
    Icons.event_available_rounded,
    const Color(0xFFE65100),
  ),
  _Category(
    'parklar',
    AppStrings.get('cat_parks', lang),
    Icons.park_rounded,
    const Color(0xFF43A047),
  ),
  _Category(
    'lokantalar',
    AppStrings.get('cat_restaurants', lang),
    Icons.restaurant_rounded,
    const Color(0xFFFB8C00),
  ),
  _Category(
    'pazar',
    AppStrings.get('cat_markets', lang),
    Icons.shopping_basket_rounded,
    const Color(0xFFFFB300),
  ),
  _Category(
    'spor',
    AppStrings.get('cat_sports', lang),
    Icons.sports_soccer_rounded,
    const Color(0xFF1E88E5),
  ),
  _Category(
    'kultur',
    AppStrings.get('cat_culture', lang),
    Icons.museum_rounded,
    const Color(0xFF8E24AA),
  ),
  _Category(
    'belediye',
    AppStrings.get('cat_municipality', lang),
    Icons.account_balance_rounded,
    _C.navy,
  ),
];

List<HistoricPlace> _getFallbackPlaces(String lang) {
  final isEn = lang == 'en';
  final isAr = lang == 'ar';

  final catCamiler = AppStrings.get('filter_mosques', lang);
  final catTarihi = AppStrings.get('filter_historic', lang);
  final catDoga = AppStrings.get('filter_nature', lang);
  final catMuzeler = AppStrings.get('filter_museums', lang);

  return [
    HistoricPlace(
      id: 'cmp_camii',
      name: isEn
          ? 'Coban Mustafa Pasha Mosque & Complex'
          : isAr
          ? 'جامع ومجمع جوبان مصطفى باشا'
          : 'Çoban Mustafa Paşa Camii ve Külliyesi',
      summary: isEn
          ? 'Built in 1523 by Coban Mustafa Pasha, it is one of the most significant Ottoman works in Gebze.'
          : isAr
          ? 'شيده جوبان مصطفى باشا عام 1523، وهو من أهم الآثار العثمانية في جبزة.'
          : 'Çoban Mustafa Paşa\'nın 1523\'te yaptırdığı cami ve külliye, Gebze\'nin en önemli Osmanlı eserlerinden biridir.',
      detailUrl: 'https://www.gebze.bel.tr/gebze-tarihi-yerler_coban-mustafa-pasa-camii-ve-kulliyesi_1.html',
      image: 'gorsel/tarihi_yerler/cmpasa.jpg',
      category: catCamiler,
    ),
    HistoricPlace(
      id: 'sultan_orhan',
      name: isEn
          ? 'Sultan Orhan Mosque'
          : isAr
          ? 'جامع السلطان أورهان'
          : 'Sultan Orhan Camii',
      summary: isEn
          ? 'Built around 1323-1331 by Orhan Bey, a prime example of early Ottoman architecture.'
          : isAr
          ? 'شيده أورهان باي في حوالي 1323-1331، وهو نموذج أنيق للعمارة العثمانية المبكرة.'
          : 'Yaklaşık 1323-1331 yıllarında Orhan Bey tarafından yaptırılan, ilk dönem Osmanlı mimarisinin sade bir örneği.',
      detailUrl: 'https://www.gebze.bel.tr/gebze/sultan-orhan-camii_2.html',
      image: 'gorsel/tarihi_yerler/sorhan.jpg',
      category: catCamiler,
    ),
    HistoricPlace(
      id: 'ilyas_bey',
      name: isEn
          ? 'Ilyas Bey Mosque'
          : isAr
          ? 'جامع إلياس باي'
          : 'İlyas Bey Camii',
      summary: isEn
          ? 'Considered the oldest surviving Ottoman mosque in the district, featuring classic stonework.'
          : isAr
          ? 'يُعد أقدم مسجد عثماني قائم في المنطقة مع كتابة بخط الثلث عند مدخله.'
          : 'Osmanlı\'dan kalan en eski cami olarak kabul edilir. Kubbesizdir, girişinde sülüs yazılı bir kitabe bulunur.',
      detailUrl:
          'https://www.gebze.bel.tr/gebze-tarihi-yerler_ilyas-bey-camii_3.html',
      image: 'gorsel/tarihi_yerler/ilyasb.jpg',
      category: catCamiler,
    ),
    HistoricPlace(
      id: 'anibal',
      name: isEn
          ? "Hannibal's Tomb"
          : isAr
          ? 'قبر حنبعل'
          : 'Anibal\'ın (Hannibal) Mezarı',
      summary: isEn
          ? 'A 24-ton stone sarcophagus surrounded by cypresses explaining the commander\'s life in five languages.'
          : isAr
          ? 'ضريح صخري ضخم يزن 24 طناً محاط بأشجار السرو يشرح سيرة القائد بخمس لغات.'
          : 'Selvilerle çevrili alanda duran 24 tonluk taş lahit, beş dilde yazılmış kitabelerle komutanın hayatını anlatır.',
      detailUrl:
          'https://www.gebze.bel.tr/gebze-tarihi-yerler_anibalin-mezari_4.html',
      image: 'gorsel/tarihi_yerler/anibal.jpg',
      category: catTarihi,
    ),
    HistoricPlace(
      id: 'hunkar',
      name: isEn
          ? 'Hunkar Cayiri'
          : isAr
          ? 'مرج هونكار'
          : 'Hünkar Çayırı',
      summary: isEn
          ? 'The historic meadow where Mehmed the Conqueror camped with his army in 1481.'
          : isAr
          ? 'المرج التاريخي الذي عسكر فيه السلطان محمد الفاتح بجيشه عام 1481.'
          : 'Fatih Sultan Mehmet\'in 1481\'de ordusunu dinlendirdiği çayırlık alan. Bugün park olarak düzenlenmiştir.',
      detailUrl:
          'https://www.gebze.bel.tr/gebze-tarihi-yerler_hunkar-cayiri_5.html',
      image: 'gorsel/tarihi_yerler/hunkar.jpg',
      category: catDoga,
    ),
    HistoricPlace(
      id: 'osman_hamdi',
      name: isEn
          ? 'Osman Hamdi Bey Mansion'
          : isAr
          ? 'قصر عثمان حمدي باي'
          : 'Osman Hamdi Bey Yalısı',
      summary: isEn
          ? 'The historic mansion built in 1884 in Eskihisar, now serving as an art and historic museum.'
          : isAr
          ? 'القصر التاريخي الذي شيده عثمان حمدي باي عام 1884 في إسكي حصار كمتحف فني وتاريخي.'
          : 'Osman Hamdi Bey\'in 1884\'te Eskihisar\'da yaptırdığı iki katlı yalı, bugün müze olarak ziyaret edilebiliyor.',
      detailUrl: 'https://www.gebze.bel.tr/gebze-tarihi-yerler_osman-hamdi-bey-yalisi_6.html',
      image: 'gorsel/tarihi_yerler/osmanbey.jpg',
      category: catMuzeler,
    ),
    HistoricPlace(
      id: 'eskihisar_kalesi',
      name: isEn
          ? 'Eskihisar Castle'
          : isAr
          ? 'قلعة إسكي حصار'
          : 'Eskihisar Kalesi',
      summary: isEn
          ? 'A historic fortress from the Byzantine era preserving its 10 bastions and 4 gates.'
          : isAr
          ? 'قلعة تاريخية تعود للعهد البيزنطي تحافظ على أبراجها العشرة وبواباتها الأربع.'
          : 'Bizans döneminden kalma tarihi kale. 10 burcu ve 4 kapısıyla özgün yapısını büyük ölçüde korur.',
      detailUrl: 'https://www.gebze.bel.tr/gebze/eskihisar-kalesi_7.html',
      image: 'gorsel/tarihi_yerler/eskale.jpg',
      category: catTarihi,
    ),
    HistoricPlace(
      id: 'ballikayalar',
      name: isEn
          ? 'Ballikayalar Nature Park'
          : isAr
          ? 'حديقة باليكايالار الطبيعية'
          : 'Ballıkayalar',
      summary: isEn
          ? 'A stunning karst canyon famous for waterfalls, caves, trekking paths, and climbing routes.'
          : isAr
          ? 'وادي كارستي خلاب يشتهر بشلالاته، كهوفه ومسارات التسلق والتنزه الطبيعي.'
          : 'Karstik vadi; göletleri, şelaleleri, travertenleri ve çok sayıda mağarasıyla doğal güzelliğiyle öne çıkar.',
      detailUrl:
          'https://www.gebze.bel.tr/gebze-tarihi-yerler_ballikayalar_8.html',
      image: 'gorsel/tarihi_yerler/ballikaya.jpg',
      category: catDoga,
    ),
  ];
}

// ───────────────────────── Ana Ekran ─────────────────────────

class GuideScreen extends ConsumerWidget {
  final ValueChanged<int>? onNavTap;

  /// 0 = Kurumsal Hizmetler, 1 = Gebze'yi Keşfet (ana sayfadaki kısayollar için)
  final int initialTab;

  const GuideScreen({super.key, this.onNavTap, this.initialTab = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);

    return _withFont(
      context,
      AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: DefaultTabController(
          length: 2,
          initialIndex: initialTab == 1 ? 1 : 0,
          child: Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0F172A)
                : _C.bg,
            body: Column(
              children: [
                _Header(
                  lang: lang,
                  onBack: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else if (onNavTap != null) {
                      onNavTap!(0);
                    }
                  },
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _InstitutionsTab(lang: lang),
                      _DiscoverTab(lang: lang),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _BottomNav(
              index: 1,
              lang: lang,
              onTap: (i) => onNavTap?.call(i),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ana sayfadaki kısayollar için: bir kurumsal hizmet kategorisinin
/// kart listesini doğrudan açar (örn. categoryId: 'lokantalar' → Kent Lokantaları).
class GuideCategoryScreen extends ConsumerWidget {
  final String categoryId;
  const GuideCategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final category = _getCategories(lang).firstWhere(
      (c) => c.id == categoryId,
      orElse: () => _getCategories(lang).first,
    );
    return _InstitutionListScreen(category: category, lang: lang);
  }
}

class _Header extends StatelessWidget {
  final String lang;
  final VoidCallback? onBack;
  const _Header({required this.lang, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.navy, _C.navyDeep],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x330A2A66),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 16, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        onBack ??
                        () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      AppStrings.get('guide_screen_title', lang),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.explore_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              indicatorColor: _C.orange,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: AppStrings.get('tab_institutions', lang)),
                Tab(text: AppStrings.get('tab_discover', lang)),
              ],
            ),
            const SizedBox(height: 6),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : _C.field,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : _C.textDark,
        ),
        decoration: InputDecoration(
          filled: false,
          fillColor: Colors.transparent,
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
            fontSize: 14,
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
    );
  }
}

// ───────────────────────── Sekme 1: Kurumsal Hizmetler ─────────────────────────

class _InstitutionsTab extends StatefulWidget {
  final String lang;
  const _InstitutionsTab({required this.lang});

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
    final categories = _getCategories(widget.lang);
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? categories
        : categories.where((c) => c.title.toLowerCase().contains(q)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _SearchField(
            controller: _ctrl,
            hint: AppStrings.get('search_institution_hint', widget.lang),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    AppStrings.get('no_institution_found', widget.lang),
                    style: const TextStyle(
                      color: _C.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _CategoryTile(
                    category: items[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _InstitutionListScreen(
                          category: items[i],
                          lang: widget.lang,
                        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : _C.line),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : _C.textDark,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kurum listesi ekranı (arama kutulu)
class _InstitutionListScreen extends StatefulWidget {
  final _Category category;
  final String lang;
  const _InstitutionListScreen({required this.category, required this.lang});

  @override
  State<_InstitutionListScreen> createState() => _InstitutionListScreenState();
}

class _InstitutionListScreenState extends State<_InstitutionListScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _matches(Map<String, dynamic> d, String q) {
    if (q.isEmpty) return true;
    final text = [
      d['name'],
      d['description'],
      d['address'],
      d['phone'],
    ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');
    return text.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final lang = widget.lang;
    final q = _query.trim().toLowerCase();
    return _withFont(
      context,
      Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : _C.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          scrolledUnderElevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_C.navy, _C.navyDeep],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          title: Text(
            category.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: category.id == 'etkinlikler'
              ? FirebaseFirestore.instance.collection('events').snapshots()
              : FirebaseFirestore.instance
                    .collection('guide_institutions')
                    .where('category', isEqualTo: category.id)
                    .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data?.docs ?? [];
            List<Map<String, dynamic>> rawItems;
            if (category.id == 'etkinlikler') {
              if (docs.isEmpty) {
                rawItems = [
                  {
                    'name': 'Gebze Kültür Sanat Buluşmaları',
                    'description': 'Osman Hamdi Bey Kültür Merkezi\'nde tiyatro ve söyleşi programı.',
                    'address': 'Osman Hamdi Bey Kültür Merkezi, Gebze',
                    'phone': '0262 642 04 30',
                    'date': '24 Ekim 2026',
                  },
                  {
                    'name': 'Gençlik & Spor Festivali',
                    'description': 'Gebze genelindeki genç sporcuların katılımıyla turnuvalar ve konser.',
                    'address': 'Gebze Kapalı Spor Salonu',
                    'phone': '0262 641 10 10',
                    'date': '28 Ekim 2026',
                  },
                  {
                    'name': 'Doğa Yürüyüşü & Bisiklet Günü',
                    'description': 'Gaziler Dağı Tabiat Parkı\'nda açık hava rekreasyon ve bisiklet parkuru.',
                    'address': 'Gaziler Dağı Tabiat Parkı, Gebze',
                    'phone': '0262 642 04 30',
                    'date': '2 Kasım 2026',
                  },
                ];
              } else {
                rawItems = docs.map((d) {
                  final m = d.data();
                  final subtitle =
                      (m['subtitle'] ?? m['description'] ?? '').toString();
                  // 'location/address' yoksa mekanı alt başlıktan al:
                  // "Osman Hamdi Bey Kültür Merkezi • 19:30" → "Osman Hamdi Bey Kültür Merkezi"
                  final venue = subtitle.split('•').first.trim();
                  final loc = (m['location'] ?? m['address'] ?? '')
                      .toString()
                      .trim();
                  final place = loc.isNotEmpty ? loc : venue;
                  return {
                    'name': m['title'] ?? m['name'] ?? '',
                    'description': subtitle,
                    'address': place.isNotEmpty ? place : 'Gebze',
                    'mapQuery': place,
                    'lat': m['lat'] ?? m['latitude'],
                    'lng': m['lng'] ?? m['longitude'],
                    'phone': m['phone'] ?? '',
                    'image': m['image'] ?? '',
                  };
                }).toList();
              }
            } else {
              if (snap.hasError || docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      AppStrings.get('no_category_records', lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _C.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }
              rawItems = docs.map((d) => d.data()).toList();
            }
            final items = rawItems.where((d) => _matches(d, q)).toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: _SearchField(
                    controller: _ctrl,
                    hint: _t(lang, 'Ara...', 'Search...', 'بحث...'),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            _t(
                              lang,
                              'Sonuç bulunamadı',
                              'No results found',
                              'لم يتم العثور على نتائج',
                            ),
                            style: const TextStyle(
                              color: _C.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) => _InstitutionCard(
                            data: items[i],
                            color: category.color,
                            lang: lang,
                            showMenuButton: category.id == 'lokantalar',
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Google Maps yol tarifi linki. Koordinat (lat/lng) varsa onu kullanır,
/// yoksa "ad adres Gebze" metniyle arar.
String _directionsUrl(Map<String, dynamic> data, String name, String address) {
  final lat = double.tryParse('${data['lat'] ?? data['latitude'] ?? ''}');
  final lng = double.tryParse('${data['lng'] ?? data['longitude'] ?? ''}');
  final String dest;
  if (lat != null && lng != null) {
    dest = '$lat,$lng';
  } else {
    // Etkinliklerde etkinlik adı yerine mekan adıyla ara (mapQuery).
    final mapQuery = (data['mapQuery'] ?? '').toString().trim();
    final text = [mapQuery.isNotEmpty ? mapQuery : name, if (mapQuery.isEmpty) address, 'Gebze Kocaeli']
        .where((s) => s.trim().isNotEmpty)
        .join(' ');
    dest = Uri.encodeComponent(text);
  }
  return 'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving';
}

class _InstitutionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color color;
  final String lang;
  final bool showMenuButton;
  const _InstitutionCard({
    required this.data,
    required this.color,
    required this.lang,
    this.showMenuButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? '').toString();
    final address = (data['address'] ?? '').toString();
    final phone = (data['phone'] ?? '').toString();
    final desc = (data['description'] ?? '').toString();
    final image = (data['image'] ?? '').toString().trim();
    final menuUrl = (data['menuUrl'] ?? '').toString().trim();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : _C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image.isNotEmpty)
            _CardImage(image: image, height: 150, color: color),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : _C.textDark,
                  ),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                    ),
                  ),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_rounded, size: 16, color: color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
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
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _openUrl(context, 'tel:$phone', lang),
                    child: Row(
                      children: [
                        Icon(Icons.phone_rounded, size: 16, color: color),
                        const SizedBox(width: 6),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Yol tarifi: koordinat varsa onu, yoksa ad + adresi hedef alır.
                // Telefonda Google Maps / varsayılan harita uygulaması açılır.
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openUrl(
                      context,
                      _directionsUrl(data, name, address),
                      lang,
                    ),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: Text(
                      _t(lang, 'Yol Tarifi', 'Directions', 'الاتجاهات'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (showMenuButton || menuUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (menuUrl.isEmpty) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  _t(
                                    lang,
                                    'Menü bağlantısı yakında eklenecek.',
                                    'Menu link coming soon.',
                                    'رابط القائمة قريباً.',
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          return;
                        }
                        _openUrl(context, menuUrl, lang);
                      },
                      icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                      label: Text(
                        _t(lang, 'Menüyü Gör', 'View Menu', 'عرض القائمة'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Asset (`gorsel/...`) veya ağ (`https://...`) görseli; hata/yüklenirken placeholder.
class _CardImage extends StatelessWidget {
  final String image;
  final double height;
  final Color color;
  const _CardImage({
    required this.image,
    required this.height,
    required this.color,
  });

  Widget _placeholder() => Container(
    height: height,
    width: double.infinity,
    color: color.withAlpha(30),
    child: Icon(Icons.image_outlined, color: color.withAlpha(140), size: 40),
  );

  @override
  Widget build(BuildContext context) {
    final path = _normalizeImagePath(image);
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, _) => _placeholder(),
        errorWidget: (_, _, _) => _placeholder(),
      );
    }
    return Image.asset(
      path,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }
}

// ───────────────────────── Sekme 2: Gebze'yi Keşfet ─────────────────────────

class _DiscoverTab extends ConsumerStatefulWidget {
  final String lang;
  const _DiscoverTab({required this.lang});

  @override
  ConsumerState<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<_DiscoverTab>
    with AutomaticKeepAliveClientMixin {
  final _ctrl = TextEditingController();
  String _query = '';
  String _filter = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _filter = AppStrings.get('filter_all', widget.lang);
  }

  @override
  void didUpdateWidget(covariant _DiscoverTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lang != widget.lang) {
      _filter = AppStrings.get('filter_all', widget.lang);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<HistoricPlace> _applyFilters(
    List<HistoricPlace> all,
    String filterAll,
    String favLabel,
    Set<String> favIds,
  ) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      final okCat =
          _filter == filterAll ||
          (_filter == favLabel
              ? favIds.contains(p.id)
              : p.category == _filter);
      final okQuery =
          q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.summary.toLowerCase().contains(q);
      return okCat && okQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filterAll = AppStrings.get('filter_all', widget.lang);
    final favIds = ref.watch(favoriteIdsProvider);
    final favLabel = _t(widget.lang, 'Favorilerim', 'Favorites', 'المفضلة');
    final filters = [
      filterAll,
      favLabel,
      AppStrings.get('filter_historic', widget.lang),
      AppStrings.get('filter_museums', widget.lang),
      AppStrings.get('filter_nature', widget.lang),
      AppStrings.get('filter_mosques', widget.lang),
    ];

    final fallbackPlaces = _getFallbackPlaces(widget.lang);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: _ctrl,
                  hint: AppStrings.get('search_places_hint', widget.lang),
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
                    widget.lang,
                  ),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.map_rounded, color: _C.navy, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = filters[i];
              final isSel = cat == _filter;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return ChoiceChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel
                        ? Colors.white
                        : (isDark ? Colors.white : _C.textDark),
                  ),
                ),
                selected: isSel,
                selectedColor: isDark ? const Color(0xFF2563EB) : _C.navy,
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                side: BorderSide(
                  color: isSel
                      ? (isDark ? const Color(0xFF2563EB) : _C.navy)
                      : (isDark ? const Color(0xFF334155) : _C.line),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                showCheckmark: false,
                onSelected: (_) => setState(() => _filter = cat),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('guide_places')
                .snapshots(),
            builder: (context, snap) {
              final List<HistoricPlace> basePlaces;
              if (snap.hasData && snap.data!.docs.isNotEmpty) {
                basePlaces = snap.data!.docs
                    .map((d) => HistoricPlace.fromMap(d.id, d.data()))
                    .toList();
              } else {
                basePlaces = fallbackPlaces;
              }

              final filtered = _applyFilters(basePlaces, filterAll, favLabel, favIds);

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    AppStrings.get('no_places_found', widget.lang),
                    style: const TextStyle(
                      color: _C.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final p = filtered[i];
                  return _PlaceCard(
                    place: p,
                    isFavorite: favIds.contains(p.id),
                    onFavorite: () async {
                      if (!requireLogin(context, ref)) return;
                      await ref.read(favoritesServiceProvider).toggle(p);
                    },
                    // Doğrudan internete gitmek yerine önce uygulama içi önizleme açılır.
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            _PlaceDetailScreen(place: p, lang: widget.lang),
                      ),
                    ),
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
    child: Center(child: Icon(place.icon, color: Colors.white54, size: 56)),
  );

  @override
  Widget build(BuildContext context) {
    final raw = place.image;
    if (raw == null || raw.trim().isEmpty) return _placeholder();
    final img = _normalizeImagePath(raw);

    if (img.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: img,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, _) => _placeholder(),
        errorWidget: (_, _, _) => _placeholder(),
      );
    }

    return Image.asset(
      img,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : _C.line),
      ),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                        horizontal: 12,
                        vertical: 5,
                      ),
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
                      color: isDark ? const Color(0xFF334155) : Colors.white,
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : _C.textDark,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (place.distanceKm != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F2D4A)
                                  : const Color(0xFFE3F4FB),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: Color(0xFF0288D1),
                                ),
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
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
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

// ───────────────────────── Mekan Önizleme Sayfası ─────────────────────────

class _PlaceDetailScreen extends StatelessWidget {
  final HistoricPlace place;
  final String lang;
  const _PlaceDetailScreen({required this.place, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _withFont(
      context,
      Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : _C.bg,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_C.navy, _C.navyDeep],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x330A2A66),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 16, 22),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _t(
                            lang,
                            'Mekan Önizlemesi',
                            'Place Preview',
                            'معاينة المكان',
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: _PlaceImage(place: place, height: 230),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : _C.navyDeep.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                        border: isDark
                            ? Border.all(color: const Color(0xFF334155))
                            : null,
                      ),
                      child: Text(
                        place.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF93C5FD) : _C.navyDeep,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      place.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : _C.textDark,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      place.summary,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: isDark ? const Color(0xFFCBD5E1) : _C.textDark,
                      ),
                    ),
                    if (place.detailUrl.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                          border: isDark
                              ? Border.all(color: const Color(0xFF334155))
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: _C.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _t(
                                  lang,
                                  'Daha fazla bilgi için aşağıdaki butona dokunduğunuzda Gebze Belediyesi web sitesine (internet tarayıcısına) yönlendirileceksiniz.',
                                  'Tapping the button below will take you to the Gebze Municipality website (your internet browser) for more information.',
                                  'عند الضغط على الزر أدناه سيتم تحويلك إلى موقع بلدية جبزة (متصفح الإنترنت) لمزيد من المعلومات.',
                                ),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: isDark
                                      ? const Color(0xFFE2E8F0)
                                      : _C.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _openUrl(context, place.detailUrl, lang),
                          icon: const Icon(
                            Icons.open_in_browser_rounded,
                            size: 20,
                          ),
                          label: Text(
                            _t(
                              lang,
                              'Devamını Tarayıcıda Aç',
                              'Continue in Browser',
                              'متابعة في المتصفح',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF2563EB)
                                : _C.navy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Alt Menü ─────────────────────────

class _BottomNav extends StatelessWidget {
  final int index;
  final String lang;
  final ValueChanged<int> onTap;
  const _BottomNav({
    required this.index,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      _NavItem(AppStrings.get('nav_home', lang), Icons.home_rounded),
      _NavItem(AppStrings.get('nav_guide', lang), Icons.explore_outlined),
      _NavItem(AppStrings.get('nav_report', lang), Icons.photo_camera_outlined),
      _NavItem(AppStrings.get('nav_services', lang), Icons.grid_view_rounded),
      _NavItem(
        AppStrings.get('nav_profile', lang),
        Icons.person_outline_rounded,
      ),
    ];

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
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i].icon,
                          size: 28,
                          color: i == index ? _C.orange : Colors.white70,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: i == index
                                ? FontWeight.w800
                                : FontWeight.w500,
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