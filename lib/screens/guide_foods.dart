import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

String _t(String lang, String tr, String en, String ar) =>
    lang == 'en' ? en : (lang == 'ar' ? ar : tr);

String _norm(String p) => p.trim().replaceAll('\\', '/');

class GebzeFood {
  final String id;
  final Map<String, dynamic> _m;
  final int order;

  GebzeFood(this.id, this._m) : order = (_m['order'] as num?)?.toInt() ?? 999;

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

  String get image => (_m['image'] ?? '').toString();
}

class GuideFoodsView extends StatefulWidget {
  final String lang;
  const GuideFoodsView({super.key, required this.lang});

  @override
  State<GuideFoodsView> createState() => _GuideFoodsViewState();
}

class _GuideFoodsViewState extends State<GuideFoodsView> {
  final _ctrl = TextEditingController();
  String _query = '';
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _foodsStream =
      FirebaseFirestore.instance
          .collection('guide_foods')
          .limit(50)
          .snapshots();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : _C.field,
              borderRadius: BorderRadius.circular(24),
              border: isDark
                  ? Border.all(color: const Color(0xFF334155))
                  : null,
            ),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : _C.textDark,
              ),
              decoration: InputDecoration(
                filled: false,
                hintText: _t(
                  lang,
                  'Lezzet ara...',
                  'Search dishes...',
                  'ابحث عن طبق...',
                ),
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
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _foodsStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final foods =
                  (snap.data?.docs ?? [])
                      .map((d) => GebzeFood(d.id, d.data()))
                      .toList()
                    ..sort((a, b) => a.order.compareTo(b.order));

              final q = _query.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? foods
                  : foods
                        .where(
                          (f) =>
                              f.text('name', lang).toLowerCase().contains(q) ||
                              f.text('summary', lang).toLowerCase().contains(q),
                        )
                        .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _t(
                        lang,
                        'Henüz lezzet eklenmedi.',
                        'No dishes added yet.',
                        'لم تتم إضافة أطباق بعد.',
                      ),
                      style: const TextStyle(
                        color: _C.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _FoodCard(
                  food: filtered[i],
                  lang: lang,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          FoodDetailScreen(food: filtered[i], lang: lang),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FoodImage extends StatelessWidget {
  final String image;
  final double height;
  const _FoodImage({required this.image, required this.height});

  Widget _placeholder() => Container(
    height: height,
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFA11F), Color(0xFFFF6A00)],
      ),
    ),
    child: const Center(
      child: Icon(Icons.restaurant_rounded, color: Colors.white70, size: 56),
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

class _FoodCard extends StatelessWidget {
  final GebzeFood food;
  final String lang;
  final VoidCallback onTap;
  const _FoodCard({
    required this.food,
    required this.lang,
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
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FoodImage(image: food.image, height: 180),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.text('name', lang),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      food.text('summary', lang),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _t(lang, 'Detaylar', 'Details', 'التفاصيل'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _C.orange,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: _C.orange,
                        ),
                      ],
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

class FoodDetailScreen extends StatelessWidget {
  final GebzeFood food;
  final String lang;
  const FoodDetailScreen({super.key, required this.food, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : _C.textDark;
    final muted = isDark ? const Color(0xFFCBD5E1) : _C.textDark;

    final summary = food.text('summary', lang);
    final origin = food.text('origin', lang);
    final where = food.text('whereToEat', lang);
    final ingredients = food.list('ingredients', lang);

    final steps = food.list('recipe', lang);
    final recipeText = steps.isEmpty ? food.text('recipe', lang) : '';

    Widget section(IconData icon, String title, Widget body) => Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _C.orange),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          body,
        ],
      ),
    );

    Widget para(String s) =>
        Text(s, style: TextStyle(fontSize: 14.5, height: 1.55, color: muted));

    return Scaffold(
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
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 16, 22),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                          'Yöresel Lezzet',
                          'Local Flavor',
                          'نكهة محلية',
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: _FoodImage(image: food.image, height: 230),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.text('name', lang),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: text,
                          ),
                        ),
                        if (summary.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          para(summary),
                        ],
                        if (origin.isNotEmpty)
                          section(
                            Icons.public_rounded,
                            _t(
                              lang,
                              'Nereden Geliyor?',
                              'Where Does It Come From?',
                              'من أين أتى؟',
                            ),
                            para(origin),
                          ),
                        if (ingredients.isNotEmpty)
                          section(
                            Icons.shopping_basket_rounded,
                            _t(lang, 'Malzemeler', 'Ingredients', 'المكونات'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final i in ingredients)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(14),
                                      border: isDark
                                          ? Border.all(
                                              color: const Color(0xFF334155),
                                            )
                                          : null,
                                    ),
                                    child: Text(
                                      i,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: text,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        if (steps.isNotEmpty || recipeText.isNotEmpty)
                          section(
                            Icons.soup_kitchen_rounded,
                            _t(
                              lang,
                              'Nasıl Yapılır?',
                              'How Is It Made?',
                              'كيف يُحضَّر؟',
                            ),
                            steps.isNotEmpty
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (int i = 0; i < steps.length; i++)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                alignment: Alignment.center,
                                                decoration: const BoxDecoration(
                                                  color: _C.orange,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  '${i + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(child: para(steps[i])),
                                            ],
                                          ),
                                        ),
                                    ],
                                  )
                                : para(recipeText),
                          ),
                        if (where.isNotEmpty)
                          section(
                            Icons.place_rounded,
                            _t(
                              lang,
                              'Nerede Yenir?',
                              'Where To Eat It?',
                              'أين تتناوله؟',
                            ),
                            para(where),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
