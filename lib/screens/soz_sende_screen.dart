import 'dart:async';

import 'auth_guard.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_strings.dart';
import '../features/soz_sende/application/soz_sende_providers.dart';

/// Gebze Belediyesi - Söz Sende (Fikir, Öneri ve Oylamalar)
/// Dosya yolu: lib/screens/soz_sende_screen.dart

class _C {
  static const navy = Color(0xFF0A2A66);
  static const navyDeep = Color(0xFF061B45);
  static const orange = Color(0xFFFF7A00);
  static const bg = Color(0xFFF1F5FD);
  static const textDark = Color(0xFF0A1F44);
  static const textMuted = Color(0xFF5F6F8A);
  static const danger = Color(0xFFE5231B);
  static const green = Color(0xFF2E7D32);

  static const orangeGradient = [Color(0xFFFFA11F), Color(0xFFFF6A00)];
}

const String _kBodyFont = 'Poppins';
const List<String> _kBodyFontFallback = [
  '-apple-system',
  'Segoe UI',
  'Roboto',
  'Helvetica Neue',
  'Noto Sans',
  'Liberation Sans',
  'Arial',
  'sans-serif',
];

const List<String> _kNeighborhoods = [
  'Tümü',
  'Mustafapaşa',
  'Osman Yılmaz',
  'Arapçeşme',
  'Hacıhalil',
  'Mevlana',
  'Gaziler',
  'Eskihisar',
];

/// Firestore'daki anket seçeneklerini güvenli şekilde ayrıştırır.
/// Desteklenen formatlar:
///  - options: [{text: 'A', votes: 3}, ...]
///  - options: ['A', 'B'] + votes: [3, 5]  veya votes: {'A': 3, 'B': 5}
List<Map<String, dynamic>> _parseOptions(Map<String, dynamic> data) {
  final raw = data['options'];
  if (raw is! List) return [];
  final votes = data['votes'];
  // Yeni oylar `voteCounts.{şıkIndex}` altında sayılır; eski oylara eklenir.
  final counts = data['voteCounts'];
  final result = <Map<String, dynamic>>[];
  for (int i = 0; i < raw.length; i++) {
    final extra = (counts is Map && counts['$i'] is num)
        ? (counts['$i'] as num)
        : 0;
    final e = raw[i];
    if (e is Map) {
      final m = Map<String, dynamic>.from(e);
      m['text'] = (m['text'] ?? m['title'] ?? m['label'] ?? m['name'] ?? '')
          .toString();
      final base = (m['votes'] is num) ? (m['votes'] as num) : 0;
      m['votes'] = base + extra;
      result.add(m);
    } else {
      final text = e.toString();
      num v = 0;
      if (votes is List && i < votes.length && votes[i] is num) {
        v = votes[i] as num;
      } else if (votes is Map && votes[text] is num) {
        v = votes[text] as num;
      }
      result.add({'text': text, 'votes': v + extra});
    }
  }
  return result;
}

String _fmtDate(dynamic v) {
  if (v is Timestamp) {
    final d = v.toDate();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
  return v.toString();
}

class SozSendeScreen extends ConsumerStatefulWidget {
  const SozSendeScreen({super.key});

  @override
  ConsumerState<SozSendeScreen> createState() => _SozSendeScreenState();
}

class _SozSendeScreenState extends ConsumerState<SozSendeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  int _neighborhoodIndex = 0;

  // Oy / destek durumu artık Firestore'dan gelir (myVotesProvider,
  // mySupportedProvider). Burada yalnızca çift dokunma koruması ve
  // demo (Firestore'da olmayan) öneri destekleri tutulur.
  final Set<String> _voting = {};
  final Set<String> _demoLiked = {};

  List<Map<String, dynamic>> _getFallbackPolls(String lang) {
    final isEn = lang == 'en';
    final isAr = lang == 'ar';
    return [
      {
        'question': isEn
            ? 'Which social facility should be built in Mustafapasa Neighborhood?'
            : isAr
            ? 'ما هو المرفق الاجتماعي الذي ينبغي إنشاؤه في حي مصطفى باشا؟'
            : "Mustafapaşa Mahallesi'ne hangi sosyal tesis yapılsın?",
        'neighborhood': 'Mustafapaşa',
        'endDate': '30.10.2026',
        'options': [
          {
            'text': isEn
                ? 'Library & Study Center'
                : isAr
                ? 'مكتبة ومركز دراسة'
                : 'Kütüphane & Etüt Merkezi',
            'votes': 128,
          },
          {
            'text': isEn
                ? 'Sports Complex'
                : isAr
                ? 'مجمع رياضي'
                : 'Spor Kompleksi',
            'votes': 94,
          },
          {
            'text': isEn
                ? 'Elderly Care & Activity Center'
                : isAr
                ? 'مركز رعاية المسنين'
                : 'Yaşlı Yaşam Merkezi',
            'votes': 61,
          },
        ],
      },
      {
        'question': isEn
            ? 'Which improvement should be prioritized in Gebze Beach Park?'
            : isAr
            ? 'ما هو التطوير ذو الأولوية في حديقة شاطئ جبزة؟'
            : "Gebze Sahil Parkı'nda hangi düzenleme öncelikli olmalı?",
        'neighborhood': 'Eskihisar',
        'endDate': '25.10.2026',
        'options': [
          {
            'text': isEn
                ? 'Walking & Cycling Path'
                : isAr
                ? 'مسار المشي والدراجات'
                : 'Yürüyüş ve bisiklet yolu',
            'votes': 210,
          },
          {
            'text': isEn
                ? "Children's Playground"
                : isAr
                ? 'منطقة ألعاب أطفال'
                : 'Çocuk oyun alanı',
            'votes': 143,
          },
          {
            'text': isEn
                ? 'Lighting & Safety'
                : isAr
                ? 'الإنارة والأمان'
                : 'Aydınlatma',
            'votes': 87,
          },
        ],
      },
    ];
  }

  List<Map<String, dynamic>> _getFallbackSuggestions(String lang) {
    final isEn = lang == 'en';
    final isAr = lang == 'ar';
    return [
      {
        'title': isEn
            ? 'Additional bus stop for Hacıhalil'
            : isAr
            ? 'موقف حافلات إضافي لحي حاجي خليل'
            : "Hacıhalil'e ek otobüs durağı",
        'description': isEn
            ? 'The stop is overcrowded during morning hours, requesting extra buses and stops.'
            : isAr
            ? 'الموقف مزدحم جداً في الصباح، أطلب موقفاً إضافياً ورحلات أكثر.'
            : 'Sabah saatlerinde durak çok kalabalık oluyor, ek durak ve sefer talep ediyorum.',
        'neighborhood': 'Hacıhalil',
        'category': AppStrings.get('cat_transport', lang),
        'status': AppStrings.get('status_approved', lang),
        'approved': true,
        'likes': 34,
      },
      {
        'title': isEn
            ? 'Trash bins for Mevlana neighborhood park'
            : isAr
            ? 'سلات نفايات لحديقة حي مولانا'
            : 'Mevlana Mahallesi parkına çöp kutusu',
        'description': isEn
            ? 'Insufficient trash bins in the park, requesting more for cleanliness.'
            : isAr
            ? 'لا توجد سلات نفايات كافية في الحديقة مما يسبب التلوث.'
            : 'Parkta yeterli çöp kutusu yok, çevre kirliliği artıyor.',
        'neighborhood': 'Mevlana',
        'category': AppStrings.get('cat_environment', lang),
        'status': AppStrings.get('status_approved', lang),
        'approved': true,
        'likes': 19,
      },
    ];
  }

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _pollsStream =
      FirebaseFirestore.instance.collection('polls').limit(50).snapshots();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _suggestionsStream =
      FirebaseFirestore.instance.collection('suggestions').limit(50).snapshots();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  bool _matchesNeighborhood(Map<String, dynamic> m) {
    if (_neighborhoodIndex == 0) return true;
    final selected = _kNeighborhoods[_neighborhoodIndex];
    final n = (m['neighborhood'] ?? '').toString();
    return n == selected || n == 'Tüm Gebze';
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _vote(String key, String? docId, int optionIndex) async {
    if (!requireLogin(context, ref)) return;
    final uid = ref.read(sozUidProvider);
    if (uid == null) return;

    // Zaten oy verilmişse (Firestore + yerel kayıt) ya da işlem sürüyorsa dur.
    final voted = ref.read(myVotesProvider).value ?? const <String, int>{};
    if (voted.containsKey(key) || !_voting.add(key)) return;
    HapticFeedback.lightImpact();

    if (docId == null) {
      // Demo anket: Firestore'da yok, yalnızca yerelde hatırlanır.
      await ref.read(voteLocalStoreProvider).setVote(uid, key, optionIndex);
      _voting.remove(key);
      ref.invalidate(myVotesProvider);
      return;
    }

    // Batch çevrimdışıyken de kuyruğa alınır; arayüz Firestore'un yerel
    // önbellek akışından anında güncellenir. Commit'i beklemiyoruz.
    unawaited(
      ref.read(sozRepoProvider).vote(uid, docId, optionIndex).catchError((
        Object e,
      ) {
        _voting.remove(key);
        _snack(
          e is FirebaseException && e.code == 'permission-denied'
              ? 'Bu ankete daha önce oy verdiniz.'
              : 'Oy kaydedilemedi, lütfen tekrar deneyin.',
        );
      }),
    );
  }

  Future<void> _toggleLike(String key, String? docId) async {
    if (!requireLogin(context, ref)) return;
    final uid = ref.read(sozUidProvider);
    if (uid == null) return;
    HapticFeedback.selectionClick();

    if (docId == null) {
      // Demo öneri: yalnızca ekranda.
      setState(() {
        _demoLiked.contains(key) ? _demoLiked.remove(key) : _demoLiked.add(key);
      });
      return;
    }

    final supported = ref.read(mySupportedProvider).value ?? const <String>{};
    final nowSupport = !supported.contains(docId);
    unawaited(
      ref
          .read(sozRepoProvider)
          .setSupport(uid, docId, support: nowSupport)
          .catchError((Object e) {
            _snack('İşlem tamamlanamadı, lütfen tekrar deneyin.');
          }),
    );
  }

  void _openNewSuggestion(String lang) {
    if (!requireLogin(context, ref)) return;
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewSuggestionSheet(lang: lang),
    ).then((sent) {
      if (sent == true && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppStrings.get('suggestion_sent_toast', lang),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
              backgroundColor: _C.navyDeep,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : _C.bg,
          floatingActionButton: _tab.index == 1
              ? FloatingActionButton.extended(
                  onPressed: () => _openNewSuggestion(lang),
                  backgroundColor: _C.orange,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(
                    AppStrings.get('btn_new_suggestion', lang),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                )
              : null,
          body: Column(
            children: [
              _Header(controller: _tab, lang: lang),
              _buildNeighborhoodChips(lang),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [_buildPollsTab(lang), _buildSuggestionsTab(lang)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeighborhoodChips(String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 14, bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _kNeighborhoods.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = _neighborhoodIndex == i;
          final label = i == 0
              ? AppStrings.get('filter_all', lang)
              : _kNeighborhoods[i];
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => setState(() => _neighborhoodIndex = i),
            selectedColor: isDark ? const Color(0xFF2563EB) : _C.navy,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : _C.textDark),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? (isDark ? const Color(0xFF2563EB) : _C.navy)
                    : (isDark
                          ? const Color(0xFF334155)
                          : Colors.grey.withAlpha(50)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPollsTab(String lang) {
    final fallbackPolls = _getFallbackPolls(lang);
    final myVotes = ref.watch(myVotesProvider).value ?? const <String, int>{};

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _pollsStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              '${AppStrings.get('error_occurred', lang)}: ${snap.error}',
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Map<String, dynamic>> items;
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          items = snap.data!.docs
              .map((d) => {...d.data(), '_id': d.id})
              .toList();
        } else {
          items = fallbackPolls
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        // Mükerrer anket koruması: Aynı soruya sahip anketleri tekilleştir
        final seenPolls = <String>{};
        final uniquePolls = items.where((p) {
          final q = (p['question'] ?? p['title'] ?? p['_id'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          return seenPolls.add(q);
        }).toList();

        final filtered = uniquePolls.where(_matchesNeighborhood).toList();
        if (filtered.isEmpty) {
          return _EmptyState(
            icon: Icons.how_to_vote_outlined,
            text: AppStrings.get('no_outages_found', lang),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final p = filtered[i];
            final id = p['_id']?.toString();
            final key = id ?? (p['question'] ?? p['title'] ?? '').toString();
            return _PollCard(
              data: p,
              lang: lang,
              votedIndex: myVotes[key],
              isDemo: id == null,
              onVote: (idx) => _vote(key, id, idx),
            );
          },
        );
      },
    );
  }

  Widget _buildSuggestionsTab(String lang) {
    final fallbackSuggestions = _getFallbackSuggestions(lang);

    final supported = ref.watch(mySupportedProvider).value ?? const <String>{};
    final currentUid = ref.watch(sozUidProvider);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _suggestionsStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              '${AppStrings.get('error_occurred', lang)}: ${snap.error}',
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> items;
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          items = snap.data!.docs
              .map((d) => {...d.data(), '_id': d.id})
              .toList();
          items.sort((a, b) {
            final ta = a['createdAt'];
            final tb = b['createdAt'];
            if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
            if (ta is Timestamp) return -1;
            if (tb is Timestamp) return 1;
            return 0;
          });
        } else {
          items = fallbackSuggestions
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        // Mükerrer öneri koruması: Aynı başlığa sahip önerileri tekilleştir
        final seenSuggestions = <String>{};
        final uniqueSuggestions = items.where((s) {
          final t = (s['title'] ?? s['_id'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          return seenSuggestions.add(t);
        }).toList();

        // Onay & Moderasyon Filtresi:
        // - Admin tarafından onaylananlar (approved == true) TÜM cihazlara ve vatandaşlara gösterilir.
        // - Henüz onaylanmamış olanlar (inceleme aşamasında) YALNIZCA öneriyi yazan kullanıcının kendisine (authorUid == currentUid) gösterilir.
        final visibleSuggestions = uniqueSuggestions.where((s) {
          final isApproved = s['approved'] == true;
          final isMine = currentUid != null && s['authorUid'] == currentUid;
          return isApproved || isMine;
        }).toList();

        final filtered = visibleSuggestions
            .where(_matchesNeighborhood)
            .toList();
        if (filtered.isEmpty) {
          return _EmptyState(
            icon: Icons.lightbulb_outline_rounded,
            text: AppStrings.get('no_suggestions_found', lang),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final s = filtered[i];
            final id = s['_id']?.toString();
            final key = id ?? (s['title'] ?? '').toString();
            final isApproved = s['approved'] == true;
            final isMine = currentUid != null && s['authorUid'] == currentUid;
            return _SuggestionCard(
              data: s,
              lang: lang,
              isApproved: isApproved,
              isMine: isMine,
              liked: id != null
                  ? supported.contains(id)
                  : _demoLiked.contains(key),
              onLike: () => _toggleLike(key, id),
            );
          },
        );
      },
    );
  }
}

// ───────────────────────── Üst Başlık ─────────────────────────

class _Header extends StatelessWidget {
  final TabController controller;
  final String lang;
  const _Header({required this.controller, required this.lang});

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
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      AppStrings.get('soz_sende_title', lang),
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
                      gradient: const LinearGradient(colors: _C.orangeGradient),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 2, bottom: 12),
                child: Text(
                  AppStrings.get('soz_sende_subtitle', lang),
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: controller,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: _C.orange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: AppStrings.get('tab_polls', lang)),
                    Tab(text: AppStrings.get('tab_suggestions', lang)),
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

// ───────────────────────── Oylama Kartı ─────────────────────────

class _PollCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  final int? votedIndex;
  final bool isDemo;
  final ValueChanged<int> onVote;

  const _PollCard({
    required this.data,
    required this.lang,
    required this.votedIndex,
    required this.isDemo,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = _parseOptions(data);

    int votesOf(int i) {
      final base = ((options[i]['votes'] ?? 0) as num).toInt();
      return base + (isDemo && votedIndex == i ? 1 : 0);
    }

    final total = List.generate(
      options.length,
      votesOf,
    ).fold<int>(0, (a, b) => a + b);
    final hasVoted = votedIndex != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE4E9F2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(
                icon: Icons.location_on_rounded,
                text: (data['neighborhood'] ?? 'Gebze').toString(),
                color: isDark ? const Color(0xFF60A5FA) : _C.navy,
              ),
              const Spacer(),
              if (data['endDate'] != null)
                Text(
                  '${AppStrings.get('poll_deadline', lang)} ${_fmtDate(data['endDate'])}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (data['question'] ?? data['title'] ?? '').toString(),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : _C.textDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < options.length; i++) ...[
            _PollOption(
              text: (options[i]['text'] ?? '').toString(),
              percent: total == 0 ? 0 : votesOf(i) / total,
              showResult: hasVoted,
              selected: votedIndex == i,
              onTap: hasVoted ? null : () => onVote(i),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.people_alt_rounded,
                size: 14,
                color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                '$total ${AppStrings.get('poll_total_votes', lang)}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hasVoted) ...[
                const Spacer(),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: _C.green,
                ),
                const SizedBox(width: 4),
                Text(
                  AppStrings.get('poll_btn_voted', lang),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _C.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PollOption extends StatelessWidget {
  final String text;
  final double percent;
  final bool showResult;
  final bool selected;
  final VoidCallback? onTap;

  const _PollOption({
    required this.text,
    required this.percent,
    required this.showResult,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : _C.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? _C.orange
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE4E9F2)),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (showResult)
              FractionallySizedBox(
                widthFactor: percent.clamp(0.0, 1.0),
                child: Container(
                  color: selected
                      ? _C.orange.withAlpha(45)
                      : (isDark
                            ? const Color(0xFF1E3A8A).withAlpha(100)
                            : const Color(0xFFE3EDFC)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isDark ? Colors.white : _C.textDark,
                      ),
                    ),
                  ),
                  if (showResult)
                    Text(
                      '%${(percent * 100).round()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? _C.orange
                            : (isDark ? const Color(0xFF94A3B8) : _C.textMuted),
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

// ───────────────────────── Öneri Kartı ─────────────────────────

class _SuggestionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  final bool liked;
  final VoidCallback onLike;
  final bool isApproved;
  final bool isMine;

  const _SuggestionCard({
    required this.data,
    required this.lang,
    required this.liked,
    required this.onLike,
    this.isApproved = false,
    this.isMine = false,
  });

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('onay') || s.contains('approv') || s.contains('yayın')) {
      return _C.green;
    }
    if (s.contains('ince') || s.contains('review') || s.contains('bekle')) {
      return _C.orange;
    }
    return _C.textMuted;
  }

  String _formatStatus(String raw, bool approved) {
    if (approved) {
      return AppStrings.get('status_approved', lang);
    }
    final s = raw.toLowerCase();
    if (s.contains('onay') || s.contains('approv')) {
      return AppStrings.get('status_approved', lang);
    }
    return AppStrings.get('status_under_review', lang);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _formatStatus(
      (data['status'] ?? 'İncelemede').toString(),
      isApproved,
    );
    final sc = _statusColor(status);
    final likes = ((data['likes'] ?? 0) as num).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: !isApproved
              ? (isDark ? const Color(0xFFB45309) : const Color(0xFFFDBA74))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE4E9F2)),
          width: !isApproved ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isApproved) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3B2508)
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFB45309)
                      : const Color(0xFFFED7AA),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    size: 15,
                    color: Color(0xFFEA580C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.get('status_under_review_desc', lang),
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFFED7AA)
                            : const Color(0xFF9A3412),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Badge(
                icon: Icons.location_on_rounded,
                text: (data['neighborhood'] ?? 'Gebze').toString(),
                color: isDark ? const Color(0xFF60A5FA) : _C.navy,
              ),
              if (data['category'] != null)
                _Badge(
                  icon: Icons.category_rounded,
                  text: data['category'].toString(),
                  color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                ),
              if (isMine && !isApproved)
                _Badge(
                  icon: Icons.person_rounded,
                  text: AppStrings.get('status_only_you_see', lang),
                  color: const Color(0xFFEA580C),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sc.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isApproved
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      size: 12,
                      color: sc,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: sc,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (data['title'] ?? '').toString(),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : _C.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (data['description'] ?? '').toString(),
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? const Color(0xFFCBD5E1) : _C.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isApproved) ...[
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_clock_outlined,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : _C.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppStrings.get(
                              'status_voting_disabled_pending',
                              lang,
                            ),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : _C.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                InkWell(
                  onTap: onLike,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          liked
                              ? Icons.thumb_up_alt_rounded
                              : Icons.thumb_up_alt_outlined,
                          size: 16,
                          color: liked
                              ? _C.orange
                              : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : _C.textMuted),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$likes ${liked ? AppStrings.get('btn_supported', lang) : AppStrings.get('btn_support', lang)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: liked
                                ? _C.orange
                                : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : _C.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Badge({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: _C.textMuted),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              color: _C.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Yeni Öneri Formu ─────────────────────────

class _NewSuggestionSheet extends StatefulWidget {
  final String lang;
  const _NewSuggestionSheet({required this.lang});

  @override
  State<_NewSuggestionSheet> createState() => _NewSuggestionSheetState();
}

class _NewSuggestionSheetState extends State<_NewSuggestionSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String _neighborhood = _kNeighborhoods[1];
  late String _category;
  bool _sending = false;
  String? _error;

  List<String> _getCategories() => [
    AppStrings.get('cat_transport', widget.lang),
    AppStrings.get('cat_environment', widget.lang),
    AppStrings.get('cat_parks_gardens', widget.lang),
    AppStrings.get('cat_infrastructure', widget.lang),
    AppStrings.get('cat_social_service', widget.lang),
    AppStrings.get('cat_other', widget.lang),
  ];

  @override
  void initState() {
    super.initState();
    _category = _getCategories().first;
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    final title = _title.text.trim();
    final desc = _desc.text.trim();
    if (title.length < 5 || desc.length < 10) {
      setState(
        () => _error = AppStrings.get('fill_fields_warning', widget.lang),
      );
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _sending = false;
          _error = AppStrings.get('error_occurred', widget.lang);
        });
        return;
      }
      final uid = user.uid;
      final displayName = user.displayName?.trim() ?? '';
      final email = user.email?.trim() ?? '';
      final authorName = displayName.isNotEmpty
          ? displayName
          : (email.contains('@') ? email.split('@').first : 'Vatandaş');

      await FirebaseFirestore.instance.collection('suggestions').add({
        'authorUid': uid,
        'author': authorName,
        'authorEmail': email,
        'title': title,
        'description': desc,
        'neighborhood': _neighborhood,
        'category': _category,
        'status': 'İncelemede',
        'approved': false,
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = '${AppStrings.get('error_occurred', widget.lang)}: $e';
      });
    }
  }

  InputDecoration _dec(BuildContext context, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDark ? const Color(0xFF64748B) : _C.textMuted,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : _C.bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : Colors.transparent,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : Colors.transparent,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final categories = _getCategories();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              AppStrings.get('dialog_new_suggestion_title', widget.lang),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : _C.navy,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              maxLength: 80,
              style: TextStyle(color: isDark ? Colors.white : _C.textDark),
              decoration: _dec(
                context,
                AppStrings.get('input_suggestion_title', widget.lang),
              ).copyWith(counterText: ''),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _desc,
              maxLines: 4,
              maxLength: 400,
              style: TextStyle(color: isDark ? Colors.white : _C.textDark),
              decoration: _dec(
                context,
                AppStrings.get('input_suggestion_desc', widget.lang),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _neighborhood,
                    isExpanded: true,
                    dropdownColor: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : _C.textDark,
                      fontSize: 13,
                    ),
                    decoration: _dec(
                      context,
                      AppStrings.get('input_neighborhood', widget.lang),
                    ),
                    items: _kNeighborhoods
                        .skip(1)
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: TextStyle(
                                color: isDark ? Colors.white : _C.textDark,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _neighborhood = v ?? _neighborhood),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    isExpanded: true,
                    dropdownColor: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : _C.textDark,
                      fontSize: 13,
                    ),
                    decoration: _dec(
                      context,
                      AppStrings.get('input_category', widget.lang),
                    ),
                    items: categories
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: TextStyle(
                                color: isDark ? Colors.white : _C.textDark,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _category = v ?? _category),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  color: _C.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _sending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(AppStrings.get('btn_send', widget.lang)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
