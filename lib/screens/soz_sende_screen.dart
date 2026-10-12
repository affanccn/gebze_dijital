import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gebze Belediyesi - Söz Sende (Fikir, Öneri ve Oylamalar)
/// Dosya yolu: lib/screens/soz_sende_screen.dart
///
/// Firestore koleksiyonları:
///  - polls:       { question, neighborhood, endDate, options: [ {text, votes} ] }
///  - suggestions: { title, description, neighborhood, category, status, likes, createdAt }

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

const String _kBodyFont = 'system-ui';
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

List<BoxShadow> _softShadow() => [
  BoxShadow(
    color: const Color(0xFF0A2A66).withAlpha(24),
    blurRadius: 16,
    offset: const Offset(0, 5),
  ),
];

List<Map<String, dynamic>> _readPollOptions(Map<String, dynamic> poll) {
  final rawOptions = poll['options'];
  if (rawOptions is! List) return [];

  final rawVotes = poll['votes'];
  return List.generate(rawOptions.length, (i) {
    final rawOption = rawOptions[i];
    final option = rawOption is Map
        ? Map<String, dynamic>.from(rawOption)
        : null;
    final storedVotes = rawVotes is List
        ? (i < rawVotes.length ? rawVotes[i] : null)
        : rawVotes is Map
        ? (rawVotes[i.toString()] ?? rawVotes[i])
        : null;

    return {
      'text': (option?['text'] ?? rawOption ?? '').toString(),
      'votes': _pollVoteCount(storedVotes ?? option?['votes']),
    };
  });
}

int _pollVoteCount(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

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

const List<String> _kCategories = [
  'Ulaşım',
  'Çevre',
  'Park & Bahçe',
  'Altyapı',
  'Sosyal Hizmet',
  'Diğer',
];

class SozSendeScreen extends StatefulWidget {
  const SozSendeScreen({super.key});

  @override
  State<SozSendeScreen> createState() => _SozSendeScreenState();
}

class _SozSendeScreenState extends State<SozSendeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  int _neighborhoodIndex = 0;

  // Bu oturumda verilen oylar / beğeniler (aynı cihazdan tekrar oy vermeyi engeller).
  final Map<String, int> _votedPolls = {};
  final Set<String> _likedSuggestions = {};

  // Veritabanı boşsa gösterilecek demo veriler
  static const _fallbackPolls = <Map<String, dynamic>>[
    {
      'question': 'Mustafapaşa Mahallesi\'ne hangi sosyal tesis yapılsın?',
      'neighborhood': 'Mustafapaşa',
      'endDate': '30.10.2026',
      'options': [
        {'text': 'Kütüphane & Etüt Merkezi', 'votes': 128},
        {'text': 'Spor Kompleksi', 'votes': 94},
        {'text': 'Yaşlı Yaşam Merkezi', 'votes': 61},
      ],
    },
    {
      'question': 'Gebze Sahil Parkı\'nda hangi düzenleme öncelikli olmalı?',
      'neighborhood': 'Eskihisar',
      'endDate': '25.10.2026',
      'options': [
        {'text': 'Yürüyüş ve bisiklet yolu', 'votes': 210},
        {'text': 'Çocuk oyun alanı', 'votes': 143},
        {'text': 'Aydınlatma', 'votes': 87},
      ],
    },
  ];

  static const _fallbackSuggestions = <Map<String, dynamic>>[
    {
      'title': 'Hacıhalil\'e ek otobüs durağı',
      'description': 'Sabah saatlerinde durak çok kalabalık oluyor, ek durak ve sefer talep ediyorum.',
      'neighborhood': 'Hacıhalil',
      'category': 'Ulaşım',
      'status': 'İnceleniyor',
      'likes': 34,
    },
    {
      'title': 'Mevlana Mahallesi parkına çöp kutusu',
      'description': 'Parkta yeterli çöp kutusu yok, çevre kirliliği artıyor.',
      'neighborhood': 'Mevlana',
      'category': 'Çevre',
      'status': 'Beklemede',
      'likes': 19,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {})); // FAB görünürlüğü için
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

  // ───────────── Oy verme ─────────────

  Future<void> _vote(String key, String? docId, int optionIndex) async {
    if (_votedPolls.containsKey(key)) return;
    setState(() => _votedPolls[key] = optionIndex);
    HapticFeedback.lightImpact();

    if (docId == null) return; // demo veri: sadece yerelde göster

    try {
      final ref = FirebaseFirestore.instance.collection('polls').doc(docId);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) return;
        final options = _readPollOptions(data);
        if (optionIndex < 0 || optionIndex >= options.length) {
          throw StateError('Anket seçeneği artık mevcut değil.');
        }

        final rawVotes = data['votes'];
        final votes = rawVotes is Map
            ? Map<String, dynamic>.from(rawVotes)
            : <String, dynamic>{};
        votes[optionIndex.toString()] =
            _pollVoteCount(options[optionIndex]['votes']) + 1;
        tx.update(ref, {'votes': votes});
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _votedPolls.remove(key));
      _snack('Oy kaydedilemedi: $e');
    }
  }

  // ───────────── Beğeni ─────────────

  Future<void> _toggleLike(String key, String? docId) async {
    final liked = _likedSuggestions.contains(key);
    setState(() {
      liked ? _likedSuggestions.remove(key) : _likedSuggestions.add(key);
    });
    if (docId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('suggestions')
          .doc(docId)
          .update({'likes': FieldValue.increment(liked ? -1 : 1)});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        liked ? _likedSuggestions.add(key) : _likedSuggestions.remove(key);
      });
      _snack('İşlem başarısız: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: _C.navyDeep,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openNewSuggestion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewSuggestionSheet(),
    ).then((sent) {
      if (sent == true) {
        _snack('Teşekkürler! Öneriniz belediyeye iletildi.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(
          fontFamily: _kBodyFont,
          fontFamilyFallback: _kBodyFontFallback,
        ),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: _C.bg,
          floatingActionButton: _tab.index == 1
              ? FloatingActionButton.extended(
                  onPressed: _openNewSuggestion,
                  backgroundColor: _C.orange,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text(
                    'Fikir Paylaş',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                )
              : null,
          body: Column(
            children: [
              _Header(controller: _tab),
              _buildNeighborhoodChips(),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [_buildPollsTab(), _buildSuggestionsTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeighborhoodChips() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 14, bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _kNeighborhoods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = _neighborhoodIndex == i;
          return ChoiceChip(
            label: Text(_kNeighborhoods[i]),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => setState(() => _neighborhoodIndex = i),
            selectedColor: _C.navy,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : _C.textDark,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? _C.navy : Colors.grey.withAlpha(50),
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────── Oylamalar sekmesi ─────────────

  Widget _buildPollsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('polls').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Veri yüklenemedi: ${snap.error}'));
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
          items = _fallbackPolls
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        final filtered = items.where(_matchesNeighborhood).toList();
        if (filtered.isEmpty) {
          return const _EmptyState(
            icon: Icons.how_to_vote_outlined,
            text: 'Bu mahalle için aktif oylama bulunmuyor.',
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final p = filtered[i];
            final id = p['_id'] as String?;
            final key = id ?? (p['question'] ?? '').toString();
            return _PollCard(
              data: p,
              votedIndex: _votedPolls[key],
              isDemo: id == null,
              onVote: (idx) => _vote(key, id, idx),
            );
          },
        );
      },
    );
  }

  // ───────────── Fikir & Öneriler sekmesi ─────────────

  Widget _buildSuggestionsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('suggestions').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Veri yüklenemedi: ${snap.error}'));
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> items;
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          items = snap.data!.docs
              .map((d) => {...d.data(), '_id': d.id})
              .toList();
          // Index gerektirmemesi için istemci tarafında sırala (yeni → eski)
          items.sort((a, b) {
            final ta = a['createdAt'];
            final tb = b['createdAt'];
            if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
            if (ta is Timestamp) return -1;
            if (tb is Timestamp) return 1;
            return 0;
          });
        } else {
          items = _fallbackSuggestions
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        final filtered = items.where(_matchesNeighborhood).toList();
        if (filtered.isEmpty) {
          return const _EmptyState(
            icon: Icons.lightbulb_outline_rounded,
            text: 'Henüz öneri yok. İlk fikri sen paylaş!',
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final s = filtered[i];
            final id = s['_id'] as String?;
            final key = id ?? (s['title'] ?? '').toString();
            return _SuggestionCard(
              data: s,
              liked: _likedSuggestions.contains(key),
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
  const _Header({required this.controller});

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
                  const Expanded(
                    child: Text(
                      'SÖZ SENDE',
                      style: TextStyle(
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
              const Padding(
                padding: EdgeInsets.only(left: 48, top: 2, bottom: 12),
                child: Text(
                  'Mahallen için fikir paylaş, oylamalara katıl',
                  style: TextStyle(fontSize: 12.5, color: Colors.white70),
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
                  tabs: const [
                    Tab(text: 'Oylamalar'),
                    Tab(text: 'Fikir & Öneriler'),
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
  final int? votedIndex;
  final bool isDemo;
  final ValueChanged<int> onVote;

  const _PollCard({
    required this.data,
    required this.votedIndex,
    required this.isDemo,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final options = _readPollOptions(data);

    // Demo veride oy Firestore'a yazılmadığı için ekranda +1 gösteriyoruz.
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(
                icon: Icons.location_on_rounded,
                text: (data['neighborhood'] ?? 'Tüm Gebze').toString(),
                color: _C.navy,
              ),
              const Spacer(),
              if (data['endDate'] != null)
                Text(
                  'Bitiş: ${data['endDate']}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _C.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (data['question'] ?? '').toString(),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: _C.textDark,
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
              const Icon(
                Icons.people_alt_rounded,
                size: 14,
                color: _C.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                '$total oy',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _C.textMuted,
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
                const Text(
                  'Oyunuz kaydedildi',
                  style: TextStyle(
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
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? _C.orange : Colors.grey.withAlpha(60);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _C.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (showResult)
              FractionallySizedBox(
                widthFactor: percent.clamp(0.0, 1.0),
                child: Container(
                  color: (selected ? _C.orange : _C.navy).withAlpha(30),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        color: _C.textDark,
                      ),
                    ),
                  ),
                  if (showResult)
                    Text(
                      '%${(percent * 100).round()}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: selected ? _C.orange : _C.navy,
                      ),
                    )
                  else
                    const Icon(
                      Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: _C.textMuted,
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
  final bool liked;
  final VoidCallback onLike;

  const _SuggestionCard({
    required this.data,
    required this.liked,
    required this.onLike,
  });

  Color _statusColor(String s) {
    switch (s) {
      case 'Hayata Geçti':
        return _C.green;
      case 'İnceleniyor':
        return _C.navy;
      default:
        return _C.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'Beklemede').toString();
    final likes = ((data['likes'] ?? 0) as num).toInt();
    // Demo veride beğeni yerelde +1 gösterilsin
    final shownLikes = likes + ((data['_id'] == null && liked) ? 1 : 0);
    final sc = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(
                icon: Icons.location_on_rounded,
                text: (data['neighborhood'] ?? 'Tüm Gebze').toString(),
                color: _C.navy,
              ),
              const SizedBox(width: 6),
              _Badge(
                icon: Icons.label_rounded,
                text: (data['category'] ?? 'Diğer').toString(),
                color: _C.textMuted,
              ),
              const Spacer(),
              _Badge(icon: Icons.flag_rounded, text: status, color: sc),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (data['title'] ?? '').toString(),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: _C.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (data['description'] ?? '').toString(),
            style: const TextStyle(
              fontSize: 12.5,
              color: _C.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.withAlpha(35)),
          const SizedBox(height: 6),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onLike,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        liked
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_outlined,
                        size: 18,
                        color: liked ? _C.orange : _C.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$shownLikes Destek',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: liked ? _C.orange : _C.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
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
  const _NewSuggestionSheet();

  @override
  State<_NewSuggestionSheet> createState() => _NewSuggestionSheetState();
}

class _NewSuggestionSheetState extends State<_NewSuggestionSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String _neighborhood = _kNeighborhoods[1];
  String _category = _kCategories.first;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final desc = _desc.text.trim();
    if (title.length < 5 || desc.length < 10) {
      setState(
        () => _error = 'Başlık en az 5, açıklama en az 10 karakter olmalı.',
      );
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await FirebaseFirestore.instance.collection('suggestions').add({
        'title': title,
        'description': desc,
        'neighborhood': _neighborhood,
        'category': _category,
        'status': 'Beklemede',
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Gönderilemedi: $e';
      });
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: _C.textMuted),
    filled: true,
    fillColor: _C.bg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
            const Text(
              'Fikrini Paylaş',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _C.navy,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              maxLength: 80,
              decoration: _dec('Başlık (örn. Parka bank konulsun)')
                  .copyWith(counterText: ''),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _desc,
              maxLines: 4,
              maxLength: 400,
              decoration: _dec('Detaylı açıklama...'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _neighborhood,
                    isExpanded: true,
                    decoration: _dec('Mahalle'),
                    items: _kNeighborhoods
                        .skip(1)
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _neighborhood = v ?? _neighborhood),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    isExpanded: true,
                    decoration: _dec('Kategori'),
                    items: _kCategories
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
                    : const Text('Gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
